require 'spec_helper'


class TestC
  include Comperators::Github
end

describe TestC do
  let(:cmp){ TestC.new }
  let(:auth_token){ Settings.instance.github_client_secret }

  context "commit_sha?" do
    it "returns true for a valid long SHA1 values" do
      expect(cmp.commit_sha?('37bca6cc589031e788583713c21955a334ca1774')).to be_truthy
      expect(cmp.commit_sha?('f73693a16cdf594532ee4c423a46d32ce3430c4e')).to be_truthy
      expect(cmp.commit_sha?('86c2509f4c12c5d3bf9a486925ed051666ee2d97')).to be_truthy
    end

    it "returns true for shorts shas" do
      expect(cmp.commit_sha?('37bca6c')).to be_truthy
      expect(cmp.commit_sha?('20170712')).to be_truthy
    end

    it "returns false for typical semver or tags" do
      expect(cmp.commit_sha?('1')).to be_falsey
      expect(cmp.commit_sha?('2.0')).to be_falsey
      expect(cmp.commit_sha?('3.0.0')).to be_falsey
      expect(cmp.commit_sha?('master')).to be_falsey
      expect(cmp.commit_sha?('1-abcdef01234')).to be_falsey
    end
  end

  let(:test_repo){ 'serde-rs/serde'  }
  let(:test_sha){ 'fd3d1396d33a49200daaaf8bf17eba78fe4183d8' }
  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_RUST,
      prod_type: Project::A_TYPE_CARGO,
      prod_key: 'serde',
      name: 'serde',
      version: '1.0.1'
    )
  }

  let(:dep1){
    Projectdependency.new(
      language: Product::A_LANGUAGE_RUST,
      prod_key: 'serde_derive',
      name: 'serde_derive',
      version_label: '1.0.0',
      repo_fullname: test_repo
    )
  }

  context "compare_github_version" do
    before do
      prod1.versions = []
    end

    it "returns IS_UPTODATE if github commit date >= the date of latest stable" do
      prod1.versions << Version.new(
        version: '1.0.7',
        released_at: DateTime.parse('2017-05-01')
      )

      prod1.versions << Version.new(
        version: '1.0.8',
        released_at: DateTime.parse('2017-05-24')
      )
      prod1.save

      VCR.use_cassette('github/comperator/by_commit_sha') do
        res = cmp.compare_github_version(test_sha, dep1, prod1.versions, auth_token)
        expect(res).not_to be_nil
        expect(res).to eq( Comperators::IS_UPTODATE )
      end
    end

    it "returns IS_OUTDATED if github commit date < the date of latest stable" do
      prod1.versions << Version.new(
        version: '1.0.8',
        released_at: DateTime.parse('2017-05-24')
      )

      prod1.versions << Version.new(
        version: '1.0.9',
        released_at: DateTime.parse('2017-07-01')
      )

      prod1.save

      VCR.use_cassette('github/comperator/by_commit_sha') do
        res = cmp.compare_github_version(test_sha, dep1, prod1.versions, auth_token)
        expect(res).not_to be_nil
        expect(res).to eq( Comperators::IS_OUTDATED )
      end
    end

    it  "returns IS_UNKNOWN when dependency has no repo_name" do
      dep2 = dep1.clone
      dep2[:repo_fullname] = nil

      res = cmp.compare_github_version(test_sha, dep2, prod1.versions, auth_token)
      expect(res).to eq( Comperators::IS_UNKNOWN )
    end

    it "returns IS_UPTODATE when user compares with master branch" do
      prod1.versions << Version.new(
        version: '1.0.8',
        released_at: DateTime.parse('2017-05-24')
      )

      prod1.save

      VCR.use_cassette('github/comperator/by_branch') do
        res = cmp.compare_github_version('master', dep1, prod1.versions, auth_token)
        expect(res).not_to be_nil
        expect(res).to eq( Comperators::IS_UPTODATE )
      end
    end

    it "returns IS_UPTODATE when the tag has newer release date as latest stable release" do
      prod1.versions << Version.new(
        version: '1.0.8',
        released_at: DateTime.parse('2017-05-24')
      )

      prod1.save

      VCR.use_cassette('github/comperator/by_tag') do
        res = cmp.compare_github_version('v1.0.8', dep1, prod1.versions, auth_token)
        expect(res).not_to be_nil
        expect(res).to eq( Comperators::IS_UPTODATE )
      end
    end

    it "returns IS_OUTDATED if latest stable release > tag release date" do
       prod1.versions << Version.new(
        version: '1.0.8',
        released_at: DateTime.parse('2017-05-24')
      )

       prod1.versions << Version.new(
        version: '1.0.9',
        released_at: DateTime.parse('2017-06-24')
      )

      prod1.save

      VCR.use_cassette('github/comperator/by_tag') do
        res = cmp.compare_github_version('v1.0.8', dep1, prod1.versions, auth_token)
        expect(res).not_to be_nil
        expect(res).to eq( Comperators::IS_OUTDATED )
      end

    end
  end
end
