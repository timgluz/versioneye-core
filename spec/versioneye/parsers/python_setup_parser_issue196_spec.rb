require 'spec_helper'

<<-COMMENT
This spec covers our user issue with his setup.py file
which uses more spaces and \" as string literal.
COMMENT


describe PythonSetupParser do
  context 'parse' do

    let(:testfile_url){"https://s3.amazonaws.com/veye_test_env/python_3/setup.py"}
    let(:parser){PythonSetupParser.new}
    let(:product1){ProductFactory.create_for_pip "Django", "1.4.3"}

    after :each do
      product1.delete
      Project.delete_all
      Dependency.delete_all
    end

    it "imports from S3 successfully" do
      project = parser.parse testfile_url
      project.should_not be_nil
      expect( project.projectdependencies.size ).to eq(2)
    end

  end
end
