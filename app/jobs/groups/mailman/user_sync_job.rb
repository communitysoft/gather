# frozen_string_literal: true

module Groups
  module Mailman
    # Synchronizes Gather users to Mailman users, including list memberships.
    class UserSyncJob < SyncJob
      attr_accessor :user

      # Stubbable in tests
      def self.find_mailman_user(user:)
        Groups::Mailman::User.find_by(user: user)
      end

      # Stubbable in tests
      def self.build_mailman_user(user:)
        Groups::Mailman::User.new(user: user)
      end

      def perform(user)
        # A note on error handling: Generally in this class we have tried to make it so that it is highly
        # unlikely that we would encounter 4xx-type errors (invalid input). We have done this by e.g.
        # checking for the existence of a remote user before attempting to update it. So if those
        # kind of errors occur, we'd want them to be handled by the job system and reported to admins.
        # We are never immune to 5xx, of course, if e.g. the Mailman server is down. In that case, we would
        # also want to see those errors.
        self.user = user
        with_community(user.community) do
          if (mm_user = self.class.find_mailman_user(user: user))
            sync_with_stored_mailman_user(mm_user)
          else
            sync_without_stored_mailman_user
          end
        end
      end

      private

      def sync_with_stored_mailman_user(mm_user)
        if mm_user.syncable?
          if api.user_exists?(mm_user)
            update_user_and_memberships(mm_user)
          else
            mm_user.destroy
            self.class.perform_later(user)
          end
        else
          api.delete_user(mm_user)
        end
      end

      def sync_without_stored_mailman_user
        mm_user = self.class.build_mailman_user(user: user)
        mm_user.mailman_id = api.user_id_for_email(mm_user)
        if mm_user.syncable?
          # If user already exists with local user's email, unify them and update
          if mm_user.mailman_id?
            ensure_no_duplicate_user(mm_user.mailman_id)
            update_user_and_memberships(mm_user)
          else
            create_user_and_memberships(mm_user)
          end
        # If there is a remote user with a matching email and the local user is not syncable, we need
        # to delete that remote user.
        elsif mm_user.mailman_id?
          api.delete_user(mm_user)
        end
      end

      def ensure_no_duplicate_user(mailman_id)
        return unless Groups::Mailman::User.find_by(mailman_id: mailman_id)
        raise SyncError, "duplicate mailman user found for mailman ID #{mailman_id}"
      end

      def update_user_and_memberships(mm_user)
        mm_user.save!
        api.update_user(mm_user)
        UserMembershipSyncJob.perform_later(mm_user)
      end

      def create_user_and_memberships(mm_user)
        new_mailman_id = api.create_user(mm_user)
        mm_user.update!(mailman_id: new_mailman_id)
        UserMembershipSyncJob.perform_later(mm_user)
      end
    end
  end
end