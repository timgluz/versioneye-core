class Plan < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_PLAN_TRIAL_0      = '03_trial_0'
  A_PLAN_TRIAL_1      = '03_trial_1'

  A_PLAN_PERSONAL_3   = '03_personal_3'
  A_PLAN_PERSONAL_6   = '03_personal_6'
  A_PLAN_PERSONAL_9   = '03_personal_9'

  A_PLAN_BUSINESS_25  = '03_business_25'
  A_PLAN_BUSINESS_50  = '03_business_50'
  A_PLAN_BUSINESS_100 = '03_business_100'

  field :name_id         , type: String
  field :name            , type: String
  field :price           , type: String
  field :private_projects, type: Integer

  has_many :users

  def self.by_name_id name_id
    Plan.where(:name_id => name_id).shift
  end

  def self.create_default_plans
    trial_0 = Plan.new
    trial_0.name_id = A_PLAN_TRIAL_0
    trial_0.name = 'Trial / Free'
    trial_0.price = '0'
    trial_0.private_projects = 1
    trial_0.save

    trial_1 = Plan.new
    trial_1.name_id = A_PLAN_TRIAL_1
    trial_1.name = 'Trial / 1'
    trial_1.price = '1'
    trial_1.private_projects = 2
    trial_1.save

    personal_1 = Plan.new
    personal_1.name_id = A_PLAN_PERSONAL_3
    personal_1.name = 'Personal / 3'
    personal_1.price = '3'
    personal_1.private_projects = 5
    personal_1.save

    personal_2 = Plan.new
    personal_2.name_id = A_PLAN_PERSONAL_6
    personal_2.name = 'Personal / 6'
    personal_2.price = '6'
    personal_2.private_projects = 10
    personal_2.save

    personal_3 = Plan.new
    personal_3.name_id = A_PLAN_PERSONAL_9
    personal_3.name = 'Personal / 9'
    personal_3.price = '9'
    personal_3.private_projects = 15
    personal_3.save

    business_1 = Plan.new
    business_1.name_id = A_PLAN_BUSINESS_25
    business_1.name = 'Business / 25'
    business_1.price = '25'
    business_1.private_projects = 50
    business_1.save

    business_2 = Plan.new
    business_2.name_id = A_PLAN_BUSINESS_50
    business_2.name = 'Business / 50'
    business_2.price = '50'
    business_2.private_projects = 100
    business_2.save

    business_3 = Plan.new
    business_3.name_id = A_PLAN_BUSINESS_100
    business_3.name = 'Business / 100'
    business_3.price = '100'
    business_3.private_projects = 200
    business_3.save
  end

  def self.current_plans
    Plan.where(name_id: /\A03/)
  end

  def self.free_plan
    Plan.where(name_id: A_PLAN_TRIAL_0).shift
  end

  def self.personal_plan
    Plan.where(name_id: A_PLAN_PERSONAL_3).shift
  end

  def self.business_small_plan
    Plan.where(name_id: A_PLAN_BUSINESS_25).shift
  end

  def self.business_normal_plan
    Plan.where(name_id: A_PLAN_BUSINESS_50).shift
  end

end
