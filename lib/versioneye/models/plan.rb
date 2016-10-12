class Plan < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_PERIOD_MONTHLY = 'monthly'
  A_PERIOD_YEARLY  = 'yearly'

  A_PLAN_FREE     = '04_free'

  # Monthly
  A_PLAN_MICRO    = '04_micro'    # € 7   - 5
  A_PLAN_SMALL    = '04_small'    # € 12  - 10
  A_PLAN_MEDIUM   = '04_medium'   # € 22  - 20
  A_PLAN_LARGE    = '04_large'    # € 50  - 50
  A_PLAN_XLARGE   = '04_xlarge'   # € 100 - 100
  A_PLAN_XXLARGE  = '04_xxlarge'  # € 250 - 250
  A_PLAN_XXXLARGE = '04_xxxlarge' # € 500 - 500

  # Yearly
  A_PLAN_MICRO_Y    = '04_micro_y'    # € 84   - 7   - Beginner Y
  A_PLAN_SMALL_Y    = '04_small_y'    # € 144  - 12  - Junior Y
  A_PLAN_MEDIUM_Y   = '04_medium_y'   # € 264  - 22  - Freelancer Y
  A_PLAN_LARGE_Y    = '04_large_y'    # € 600  - 52  - Advanced Y
  A_PLAN_XLARGE_Y   = '04_xlarge_y'   # € 1200 - 102 - Professional Y
  A_PLAN_XXLARGE_Y  = '04_xxlarge_y'  # € 3000 - 252 - Agency Y
  A_PLAN_XXXLARGE_Y = '04_xxxlarge_y' # € 6000 - 502 - Enterprise Y

  field :name_id         , type: String
  field :name            , type: String
  field :price           , type: String
  field :period          , type: String, default: A_PERIOD_MONTHLY
  field :private_projects, type: Integer, default: 1  # losed source projects
  field :os_projects     , type: Integer, default: 1  # OS = Open Source
  field :api_rate_limit  , type: Integer, default: 50
  field :cmp_rate_limit  , type: Integer, default: 50

  has_many :organisations

  def self.by_name_id name_id
    Plan.where(:name_id => name_id).shift
  end

  def self.create_free_plan
    trial_0 = Plan.new
    trial_0.name_id = A_PLAN_FREE
    trial_0.name = 'Free'
    trial_0.price = '0'
    trial_0.os_projects = 4
    trial_0.private_projects = 1
    trial_0.api_rate_limit   = 50
    trial_0.cmp_rate_limit   = 50
    trial_0.save
  end

  def self.create_defaults
    free = Plan.find_or_create_by(:name_id => A_PLAN_FREE)
    free.name = 'Free'
    free.price = '0'
    free.os_projects = 4
    free.private_projects = 1
    free.api_rate_limit   = 50
    free.cmp_rate_limit   = 50
    free.save

    micro = Plan.find_or_create_by(:name_id => A_PLAN_MICRO)
    micro.name = 'Beginner'
    micro.price = '7'
    micro.os_projects = 5
    micro.private_projects = 5
    micro.api_rate_limit   = 100
    micro.cmp_rate_limit   = 100
    micro.save

    small = Plan.find_or_create_by(:name_id => A_PLAN_SMALL)
    small.name = 'Junior'
    small.price = '12'
    small.os_projects = 10
    small.private_projects = 10
    small.api_rate_limit   = 150
    small.cmp_rate_limit   = 150
    small.save

    medium = Plan.find_or_create_by(:name_id => A_PLAN_MEDIUM)
    medium.name = 'Freelancer'
    medium.price = '22'
    medium.os_projects = 20
    medium.private_projects = 20
    medium.api_rate_limit   = 300
    medium.cmp_rate_limit   = 300
    medium.save

    large = Plan.find_or_create_by(:name_id => A_PLAN_LARGE)
    large.name_id = A_PLAN_LARGE
    large.name = 'Advanced'
    large.price = '50'
    large.os_projects = 50
    large.private_projects = 50
    large.api_rate_limit   = 500
    large.cmp_rate_limit   = 500
    large.save

    xlarge = Plan.find_or_create_by(:name_id => A_PLAN_XLARGE)
    xlarge.name = 'Professional'
    xlarge.price = '100'
    xlarge.os_projects = 100
    xlarge.private_projects = 100
    xlarge.api_rate_limit   = 1000
    xlarge.cmp_rate_limit   = 1000
    xlarge.save

    agency = Plan.find_or_create_by(:name_id => A_PLAN_XXLARGE)
    agency.name_id = A_PLAN_XXLARGE
    agency.name = 'Agency'
    agency.price = '250'
    agency.os_projects = 250
    agency.private_projects = 250
    agency.api_rate_limit   = 2500
    agency.cmp_rate_limit   = 2500
    agency.save

    enterprise = Plan.find_or_create_by(:name_id => A_PLAN_XXXLARGE)
    enterprise.name_id = A_PLAN_XXXLARGE
    enterprise.name = 'Enterprise'
    enterprise.price = '500'
    enterprise.os_projects = 500
    enterprise.private_projects = 500
    enterprise.api_rate_limit   = 5000
    enterprise.cmp_rate_limit   = 5000
    enterprise.save

    micro_y = Plan.find_or_create_by(:name_id => A_PLAN_MICRO_Y)
    micro_y.name = 'Beginner Y'
    micro_y.price = '84'
    micro_y.period = A_PERIOD_YEARLY
    micro_y.os_projects = 7
    micro_y.private_projects = 7
    micro_y.api_rate_limit   = 100
    micro_y.cmp_rate_limit   = 100
    micro_y.save

    small_y = Plan.find_or_create_by(:name_id => A_PLAN_SMALL_Y)
    small_y.name = 'Junior Y'
    small_y.price = '144'
    small_y.period = A_PERIOD_YEARLY
    small_y.os_projects = 12
    small_y.private_projects = 12
    small_y.api_rate_limit   = 150
    small_y.cmp_rate_limit   = 150
    small_y.save

    medium_y = Plan.find_or_create_by(:name_id => A_PLAN_MEDIUM_Y)
    medium_y.name = 'Freelancer Y'
    medium_y.price = '264'
    medium_y.period = A_PERIOD_YEARLY
    medium_y.os_projects = 22
    medium_y.private_projects = 22
    medium_y.api_rate_limit   = 300
    medium_y.cmp_rate_limit   = 300
    medium_y.save

    large_y = Plan.find_or_create_by(:name_id => A_PLAN_LARGE_Y)
    large_y.name = 'Advanced Y'
    large_y.price = '600'
    large_y.period = A_PERIOD_YEARLY
    large_y.os_projects = 52
    large_y.private_projects = 52
    large_y.api_rate_limit   = 500
    large_y.cmp_rate_limit   = 500
    large_y.save

    xlarge_y = Plan.find_or_create_by(:name_id => A_PLAN_XLARGE_Y)
    xlarge_y.name = 'Professional Y'
    xlarge_y.price = '1200'
    xlarge_y.period = A_PERIOD_YEARLY
    xlarge_y.os_projects = 102
    xlarge_y.private_projects = 102
    xlarge_y.api_rate_limit   = 1000
    xlarge_y.cmp_rate_limit   = 1000
    xlarge_y.save

    agency_y = Plan.find_or_create_by(:name_id => A_PLAN_XXLARGE_Y)
    agency_y.name = 'Agency Y'
    agency_y.price = '3000'
    agency_y.period = A_PERIOD_YEARLY
    agency_y.os_projects = 252
    agency_y.private_projects = 252
    agency_y.api_rate_limit   = 2500
    agency_y.cmp_rate_limit   = 2500
    agency_y.save

    enterprise_y = Plan.find_or_create_by(:name_id => A_PLAN_XXXLARGE_Y)
    enterprise_y.name = 'Enterprise Y'
    enterprise_y.price = '6000'
    enterprise_y.period = A_PERIOD_YEARLY
    enterprise_y.os_projects = 502
    enterprise_y.private_projects = 502
    enterprise_y.api_rate_limit   = 5000
    enterprise_y.cmp_rate_limit   = 5000
    enterprise_y.save
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
