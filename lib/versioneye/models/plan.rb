class Plan < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_PLAN_FREE    = '04_free'
  A_PLAN_MICRO   = '04_micro'   # € 7   - 5
  A_PLAN_SMALL   = '04_small'   # € 12  - 10
  A_PLAN_MEDIUM  = '04_medium'  # € 22  - 20
  A_PLAN_LARGE   = '04_large'   # € 50  - 50
  A_PLAN_XLARGE  = '04_xlarge'  # € 100 - 100
  A_PLAN_XXLARGE = '04_xxlarge' # € 250 - 250

  field :name_id         , type: String
  field :name            , type: String
  field :price           , type: String
  field :private_projects, type: Integer

  has_many :users

  def self.by_name_id name_id
    Plan.where(:name_id => name_id).shift
  end

  def self.create_free_plan
    trial_0 = Plan.new
    trial_0.name_id = A_PLAN_FREE
    trial_0.name = 'Trial / Free'
    trial_0.price = '0'
    trial_0.private_projects = 1
    trial_0.save
  end

  def self.create_defaults
    micro = Plan.new
    micro.name_id = A_PLAN_FREE
    micro.name = 'Free'
    micro.price = '0'
    micro.private_projects = 1
    micro.save

    micro = Plan.new
    micro.name_id = A_PLAN_MICRO
    micro.name = 'Micro'
    micro.price = '7'
    micro.private_projects = 5
    micro.save

    small = Plan.new
    small.name_id = A_PLAN_SMALL
    small.name = 'Small'
    small.price = '12'
    small.private_projects = 10
    small.save

    medium = Plan.new
    medium.name_id = A_PLAN_MEDIUM
    medium.name = 'Medium'
    medium.price = '22'
    medium.private_projects = 20
    medium.save

    large = Plan.new
    large.name_id = A_PLAN_LARGE
    large.name = 'Large'
    large.price = '50'
    large.private_projects = 50
    large.save

    xlarge = Plan.new
    xlarge.name_id = A_PLAN_XLARGE
    xlarge.name = 'X-Large'
    xlarge.price = '100'
    xlarge.private_projects = 100
    xlarge.save

    xxlarge = Plan.new
    xxlarge.name_id = A_PLAN_XXLARGE
    xxlarge.name = 'XX-Large'
    xxlarge.price = '250'
    xxlarge.private_projects = 250
    xxlarge.save
  end

  def self.current_plans
    Plan.where(name_id: /\A04/)
  end

  def self.free_plan
    Plan.where(name_id: A_PLAN_FREE).shift
  end

  def self.micro
    Plan.where(name_id: A_PLAN_MICRO).shift
  end

  def self.small
    Plan.where(name_id: A_PLAN_SMALL).shift
  end

  def self.medium
    Plan.where(name_id: A_PLAN_MEDIUM).shift
  end

  def self.large
    Plan.where(name_id: A_PLAN_LARGE).shift
  end

  def self.xlarge
    Plan.where(name_id: A_PLAN_XLARGE).shift
  end

end
