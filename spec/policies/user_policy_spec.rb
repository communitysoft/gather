require 'rails_helper'

describe UserPolicy do
  include_context "policy objs"

  describe "permissions" do
    let(:record) { other_user }

    permissions :index? do
      it "grants access to active users" do
        expect(subject).to permit(user, User)
      end

      it "denies access to inactive users" do
        expect(subject).not_to permit(inactive_user, User)
      end
    end

    permissions :show? do
      it_behaves_like "grants access to users in cluster"

      context "for inactive user" do
        it "denies access to other users" do
          expect(subject).not_to permit(inactive_user, other_user)
        end

        it "allows access to self" do
          expect(subject).to permit(inactive_user, inactive_user)
        end
      end
    end

    permissions :new?, :create?, :invite?, :send_invites? do
      it_behaves_like "admins only"
    end

    permissions :activate?, :deactivate?, :administer?, :add_basic_role? do
      it_behaves_like "admins only"

      it "denies access to self" do
        expect(subject).not_to permit(user, user)
      end

      it "denies access to guardians for own children" do
        expect(subject).not_to permit(guardian, child)
      end
    end

    permissions :cluster_adminify? do
      it "grants access to cluster admin and above" do
        expect(subject).to permit(cluster_admin, user)
      end

      it "denies access to regular admins" do
        expect(subject).not_to permit(admin, user)
      end
    end

    permissions :super_adminify? do
      it "grants access to super admin" do
        expect(subject).to permit(super_admin, user)
      end

      it "denies access to cluster admins" do
        expect(subject).not_to permit(cluster_admin, user)
      end
    end

    permissions :edit?, :update? do
      it_behaves_like "admins only"

      it "grants access to self" do
        expect(subject).to permit(user, user)
      end

      it "allows guardians to edit own children" do
        expect(subject).to permit(guardian, child)
      end

      it "disallows guardians from editing other children" do
        expect(subject).not_to permit(guardian, other_child)
      end

      it "disallows children from editing parent" do
        expect(subject).not_to permit(child, guardian)
      end

      it "grants access to self for inactive user" do
        expect(subject).to permit(inactive_user, inactive_user)
      end
    end

    permissions :destroy? do
      shared_examples_for "full denial" do
        it "denies access to admins" do
          expect(subject).not_to permit(admin, user)
        end
      end

      context "with assignments" do
        before { allow(user).to receive(:any_assignments?).and_return(true) }
        it_behaves_like "full denial"
      end

      context "without assignment" do
        before { allow(user).to receive(:any_assignments?).and_return(false) }
        it_behaves_like "admins only"
      end
    end
  end

  describe "scope" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:deactivated) { create(:user, deactivated_at: Time.now - 1.day) }

    context "for admin" do
      let!(:admin) { create(:admin) }

      it "returns active users" do
        permitted = UserPolicy::Scope.new(admin, User.all).resolve
        expect(permitted).to contain_exactly(user1, user2, deactivated, admin)
      end
    end

    context "for regular user" do
      it "returns active users" do
        permitted = UserPolicy::Scope.new(user1, User.all).resolve
        expect(permitted).to contain_exactly(user1, user2)
      end
    end
  end

  describe "permitted attributes" do
    let(:user2) { double(community: community, household: double(community: community)) }
    let(:basic_attribs) { [:email, :first_name, :last_name, :mobile_phone, :home_phone, :work_phone,
      :photo, :photo_tmp_id, :photo_destroy, :birthdate_str, :child, :joined_on, :preferred_contact,
      :household_by_id,
      {up_guardianships_attributes: [:id, :guardian_id, :_destroy]},
      {household_attributes: [:id, :name, :garage_nums].
        concat(vehicles_and_contacts_attribs)}
    ] }
    let(:admin_attribs) { [:email, :first_name, :last_name, :mobile_phone, :home_phone, :work_phone,
      :photo, :photo_tmp_id, :photo_destroy, :birthdate_str, :child, :joined_on, :preferred_contact,
      :google_email, :alternate_id, :role_admin, :role_biller, :household_by_id,
      {up_guardianships_attributes: [:id, :guardian_id, :_destroy]},
      {household_attributes: [:id, :name, :garage_nums, :unit_num, :old_id, :old_name].
        concat(vehicles_and_contacts_attribs)}
    ] }
    let(:cluster_admin_attribs) { [:email, :first_name, :last_name, :mobile_phone, :home_phone, :work_phone,
      :photo, :photo_tmp_id, :photo_destroy, :birthdate_str, :child, :joined_on, :preferred_contact,
      :google_email, :alternate_id, :role_cluster_admin, :role_admin, :role_biller, :household_by_id,
      {up_guardianships_attributes: [:id, :guardian_id, :_destroy]},
      {household_attributes: [:id, :name, :garage_nums, :unit_num, :old_id, :old_name].
        concat(vehicles_and_contacts_attribs)}
    ] }
    let(:vehicles_and_contacts_attribs) { [
      {vehicles_attributes: [:id, :make, :model, :color, :_destroy]},
      {emergency_contacts_attributes: [:id, :name, :relationship, :main_phone, :alt_phone,
        :email, :location, :_destroy]}
    ] }
    subject { UserPolicy.new(user, user2).permitted_attributes }

    shared_examples_for "basic attribs" do
      it "should allow basic attribs" do
        expect(subject).to contain_exactly(*basic_attribs)
      end
    end

    context "regular user" do
      it_behaves_like "basic attribs"
    end

    context "admin" do
      let(:user) { admin }

      it "should allow admin attribs" do
        expect(subject).to contain_exactly(*(admin_attribs))
      end
    end

    context "admin from other community" do
      let(:user) { outside_admin }
      it_behaves_like "basic attribs"
    end

    context "cluster admin" do
      let(:user) { cluster_admin }

      it "should allow cluster admin attribs" do
        expect(subject).to contain_exactly(*cluster_admin_attribs)
      end
    end

    context "super admin" do
      let(:user) { super_admin }

      it "should allow super admin attribs" do
        expect(subject).to contain_exactly(*(cluster_admin_attribs << :role_super_admin))
      end
    end
  end
end
