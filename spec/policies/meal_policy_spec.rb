# frozen_string_literal: true

require "rails_helper"

describe MealPolicy do
  describe "permissions" do
    include_context "policy permissions"
    let(:meal) { build(:meal, community: community, communities: [community, communityC]) }
    let(:record) { meal }

    permissions :index?, :report? do
      it_behaves_like "permits users in cluster"
    end

    permissions :show?, :summary? do
      it_behaves_like "permits users in community only"

      it "permits users in other invited communities" do
        expect(subject).to permit(user_in_cmtyC, meal)
      end

      it "permits non-invited workers" do
        meal.assignments.build(user: user_in_cmtyB)
        expect(subject).to permit(user_in_cmtyB, meal)
      end

      it "permits non-invited but signed-up folks" do
        meal.signups.build(household: user_in_cmtyB.household)
        expect(subject).to permit(user_in_cmtyB, meal)
      end
    end

    permissions :new?, :create?, :administer?, :destroy?, :update_formula? do
      it_behaves_like "permits admins or special role but not regular users", :meals_coordinator
    end

    permissions :update_formula? do
      it "forbids if finalized" do
        meal.status = "finalized"
        expect(subject).not_to permit(admin, meal)
      end
    end

    permissions :edit?, :update? do
      # We let anyone in host community do this so they can change assignments.
      it_behaves_like "permits admins from community"
      it_behaves_like "permits users in community only"

      it "permits non-invited workers" do
        meal.assignments.build(user: user_in_cmtyB)
        expect(subject).to permit(user_in_cmtyB, meal)
      end
    end

    permissions :update_menu?, :close?, :cancel? do
      it_behaves_like "permits admins or special role but not regular users", :meals_coordinator

      it "permits head cook" do
        set_head_cook(user)
        expect(subject).to permit(user, meal)
      end
    end

    permissions :close?, :reopen? do
      it "denies if meal cancelled" do
        stub_status("cancelled")
        expect(subject).not_to permit(admin, meal)
      end
    end

    permissions :reopen? do
      before { meal.close! }

      it_behaves_like "permits admins or special role but not regular users", :meals_coordinator

      it "permits if day prior to meal" do
        Timecop.travel(meal.served_at - 1.day) do
          expect(subject).to permit(admin, meal)
        end
      end

      it "permits if after meal but same day" do
        Timecop.travel(meal.served_at + 1.minute) do
          expect(subject).to permit(admin, meal)
        end
      end

      it "forbids if meal open" do
        meal.reopen!
        expect(subject).not_to permit(admin, meal)
      end

      it "forbids if day after meal" do
        Timecop.travel(meal.served_at + 1.day) do
          expect(subject).not_to permit(admin, meal)
        end
      end
    end

    permissions :finalize? do
      before do
        stub_status("closed")
        meal.served_at = Time.current - 30.minutes
      end

      it_behaves_like "permits admins or special role but not regular users", :biller

      it "forbids if meal already cancelled" do
        stub_status("cancelled")
        expect(subject).not_to permit(admin, meal)
      end

      it "forbids if meal finalized" do
        stub_status("finalized")
        expect(subject).not_to permit(admin, meal)
      end
    end

    permissions :cancel? do
      it "forbids if meal already cancelled" do
        stub_status("cancelled")
        expect(subject).not_to permit(admin, meal)
      end

      it "forbids if meal finalized" do
        stub_status("finalized")
        expect(subject).not_to permit(admin, meal)
      end
    end

    permissions :send_message? do
      it_behaves_like "permits admins or special role but not regular users", :meals_coordinator

      it "permits team members" do
        meal.assignments.build(user: user)
        expect(subject).to permit(user, meal)
      end
    end
  end

  describe "scope" do
    include_context "policy scopes"
    let(:klass) { Meal }
    let!(:meal1) { create(:meal, communities: [user.community]) } # Invited
    let!(:meal2) { create(:meal, cleaners: [actor], communities: [communityB]) } # Assigned
    let!(:meal3) { create(:meal, communities: [communityB]) } # Signed up
    let!(:meal4) { create(:meal, communities: [communityB]) } # None of the above

    before do
      meal3.signups.create!(household: actor.household, adult_meat: 2)
    end

    context "as regular user" do
      let(:actor) { user }

      it "returns meals invited to, assigned to, or signed up for" do
        is_expected.to contain_exactly(meal1, meal2, meal3)
      end
    end

    context "as admin" do
      let(:actor) { admin }

      it "returns meals invited to, assigned to, or signed up for" do
        is_expected.to contain_exactly(meal1, meal2, meal3)
      end
    end

    context "as cluster admin" do
      let(:actor) { cluster_admin }

      it "returns all meals" do
        is_expected.to contain_exactly(meal1, meal2, meal3, meal4)
      end
    end

    context "as inactive user" do
      let(:actor) { inactive_user }

      it "returns meals only signed up for" do
        is_expected.to contain_exactly(meal3)
      end
    end
  end

  describe "permitted_attributes" do
    include_context "policy permissions"
    let(:meal) { build(:meal, community: community, communities: [community, communityC]) }
    let(:assign_attribs) do
      [{
        head_cook_assign_attributes: %i[id user_id],
        asst_cook_assigns_attributes: %i[id user_id _destroy],
        table_setter_assigns_attributes: %i[id user_id _destroy],
        cleaner_assigns_attributes: %i[id user_id _destroy]
      }]
    end
    let(:head_cook_attribs) { %i[allergen_dairy title capacity entrees] }
    let(:admin_attribs) { [:formula_id] }
    subject { MealPolicy.new(actor, meal).permitted_attributes }

    shared_examples_for "admin or meals coordinator" do
      it "should allow even more stuff" do
        expect(subject).to include(*(assign_attribs + head_cook_attribs) + admin_attribs)
        expect(subject).not_to include(:community_id)
      end

      it "should not allow formula_id if meal finalized" do
        meal.status = "finalized"
        expect(subject).not_to include(:formula_id)
      end
    end

    context "regular user" do
      let(:actor) { user }

      it "should allow only assignment attribs" do
        expect(subject).to contain_exactly(*assign_attribs)
      end
    end

    context "head cook" do
      let(:actor) { user }

      it "should allow more stuff" do
        set_head_cook(actor)
        expect(subject).to include(*(assign_attribs + head_cook_attribs))
        expect(subject).not_to include(*(admin_attribs + [:community_id]))
      end
    end

    context "admin" do
      let(:actor) { admin }

      it_behaves_like "admin or meals coordinator"
    end

    context "meals coordinator" do
      let(:actor) { meals_coordinator }

      it_behaves_like "admin or meals coordinator"
    end

    context "outside admin" do
      let(:actor) { admin_in_cmtyB }

      it "should have only basic attribs" do
        expect(subject).to contain_exactly(*assign_attribs)
      end
    end
  end

  def set_head_cook(user)
    save_policy_objects!(community, user)
    meal.save!
    meal.head_cook = user
  end
end
