class Plan < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_PLAN_FREE     = '04_free'
  A_PLAN_MICRO    = '04_micro'    # € 7   - 5
  A_PLAN_SMALL    = '04_small'    # € 12  - 10
  A_PLAN_MEDIUM   = '04_medium'   # € 22  - 20
  A_PLAN_LARGE    = '04_large'    # € 50  - 50
  A_PLAN_XLARGE   = '04_xlarge'   # € 100 - 100
  A_PLAN_XXLARGE  = '04_xxlarge'  # € 250 - 250
  A_PLAN_XXXLARGE = '04_xxxlarge' # € 500 - 500

  field :name_id         , type: String
  field :name            , type: String
  field :price           , type: String
  field :private_projects, type: Integer
  field :api_rate_limit  , type: Integer, default: 50
  field :cmp_rate_limit  , type: Integer, default: 50

  has_many :users
  has_many :organisations

  def self.by_name_id name_id
    Plan.where(:name_id => name_id).shift
  end

  def self.create_free_plan
    trial_0 = Plan.new
    trial_0.name_id = A_PLAN_FREE
    trial_0.name = 'Free'
    trial_0.price = '0'
    trial_0.private_projects = 1
    trial_0.api_rate_limit   = 50
    trial_0.cmp_rate_limit   = 50
    trial_0.save
  end

  def self.create_defaults
    free = Plan.find_or_create_by(:name_id => A_PLAN_FREE)
    free.name = 'Free'
    free.price = '0'
    free.private_projects = 1
    free.api_rate_limit   = 50
    free.cmp_rate_limit   = 50
    free.save

    micro = Plan.find_or_create_by(:name_id => A_PLAN_MICRO)
    micro.name = 'Beginner'
    micro.price = '7'
    micro.private_projects = 5
    micro.api_rate_limit   = 100
    micro.cmp_rate_limit   = 100
    micro.save

    small = Plan.find_or_create_by(:name_id => A_PLAN_SMALL)
    small.name = 'Junior'
    small.price = '12'
    small.private_projects = 10
    small.api_rate_limit   = 150
    small.cmp_rate_limit   = 150
    small.save

    medium = Plan.find_or_create_by(:name_id => A_PLAN_MEDIUM)
    medium.name = 'Freelancer'
    medium.price = '22'
    medium.private_projects = 20
    medium.api_rate_limit   = 300
    medium.cmp_rate_limit   = 300
    medium.save

    large = Plan.find_or_create_by(:name_id => A_PLAN_LARGE)
    large.name_id = A_PLAN_LARGE
    large.name = 'Advanced'
    large.price = '50'
    large.private_projects = 50
    large.api_rate_limit   = 500
    large.cmp_rate_limit   = 500
    large.save

    xlarge = Plan.find_or_create_by(:name_id => A_PLAN_XLARGE)
    xlarge.name = 'Professional'
    xlarge.price = '100'
    xlarge.private_projects = 100
    xlarge.api_rate_limit   = 1000
    xlarge.cmp_rate_limit   = 1000
    xlarge.save

    agency = Plan.find_or_create_by(:name_id => A_PLAN_XXLARGE)
    agency.name_id = A_PLAN_XXLARGE
    agency.name = 'Agency'
    agency.price = '250'
    agency.private_projects = 250
    agency.api_rate_limit   = 2500
    agency.cmp_rate_limit   = 2500
    agency.save

    enterprise = Plan.find_or_create_by(:name_id => A_PLAN_XXXLARGE)
    enterprise.name_id = A_PLAN_XXXLARGE
    enterprise.name = 'Enterprise'
    enterprise.price = '500'
    enterprise.private_projects = 500
    enterprise.api_rate_limit   = 5000
    enterprise.cmp_rate_limit   = 5000
    enterprise.save
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
