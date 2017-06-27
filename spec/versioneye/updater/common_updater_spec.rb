require 'spec_helper'

describe CommonUpdater do
  let(:content_without_jspm){ File.read 'spec/fixtures/files/npm/package_without_jspm.json' }
  let(:content_with_jspm){ File.read 'spec/fixtures/files/npm/package_with_jspm.json' }

  let(:user){ UserFactory.create_new }
  let(:parser){ PackageParser.new }

  describe 'update_old_with_new' do

    it 'updates old project with new values, clears the cache and dont send email' do
      ActionMailer::Base.deliveries.clear

      old_project = ProjectFactory.default user, 10
      new_project = ProjectFactory.default user, 11

      CommonUpdater.cache.set( old_project.id.to_s, "out-of-date", 21600) # TTL = 6.hour
      expect( CommonUpdater.cache.get( old_project.id.to_s) ).not_to be_nil

      CommonUpdater.new.update_old_with_new old_project, new_project

      # Expect that cache for project badge is cleared
      expect( CommonUpdater.cache.get( old_project.id.to_s) ).to be_nil

      # Epcect that 0 emails are send
      expect( ActionMailer::Base.deliveries.size ).to eq(0)
    end

  end


  describe 'updating existing Package project with a project with JSPM' do

    it 'should create attach child project to updated project' do
      old_project = parser.parse_content content_without_jspm
      old_project[:user_id] = user.ids
      expect(old_project.save).to be_truthy
      expect(old_project).not_to be_nil
      expect(old_project.dep_number).to eq(2)
      expect(old_project.children.to_a.size).to eq(0)

      new_project = parser.parse_content content_with_jspm
      new_project[:user_id] = user.ids
      expect(new_project).not_to be_nil
      expect(new_project.dep_number).to eq(5)
      expect(new_project.children.to_a.size).to eq(1)

      # move new project into old project
      CommonUpdater.new.update_old_with_new old_project, new_project
      old_project.reload
      expect(old_project).not_to be_nil
      expect(old_project.dep_number).to eq(5)
      expect(old_project.children.to_a.size).to eq(1)


    end
  end

end
