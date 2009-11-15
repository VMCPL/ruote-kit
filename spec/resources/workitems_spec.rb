require File.dirname(__FILE__) + '/../spec_helper'

describe "GET /workitems" do
  describe "without any workitems" do
    it "should report no workitems (HTML)" do
      get "/workitems"

      last_response.should be_ok
      last_response.should match(/No workitems are currently available/)
    end

    it "should report no workitems (JSON)" do
      get "/workitems.json"

      last_response.should be_ok
      json = last_response.json_body

      json.should have_key('workitems')
      json['workitems'].should be_empty
    end
  end

  describe "with workitems" do
    before(:each) do
      @wfid = launch_test_process do
        Ruote.process_definition :name => 'test' do
          sequence do
            nada :activity => 'Work your magic'
          end
        end
      end
    end

    it "should have a list of workitems (HTML)" do
      get "/workitems"

      last_response.should be_ok
      last_response.should match(/1 workitem available/)
    end

    it "should have a list of workitems (JSON)" do
      get "/workitems.json"

      last_response.should be_ok
      json = last_response.json_body

      json['workitems'].size.should be(1)

      wi = json['workitems'][0]

      wi.keys.should include('fei', 'participant_name', 'fields')
      wi['fei']['wfid'].should == @wfid
      wi['participant_name'].should == 'nada'
      wi['fields']['params']['activity'].should == 'Work your magic'
    end
  end
end

describe "GET /workitems/X-Y" do
  describe "with a workitem" do
    before(:each) do
      @wfid = launch_test_process do
        Ruote.process_definition :name => 'foo' do
          sequence do
            nada :activity => 'Work your magic'
          end
        end
      end

      process = RuoteKit.engine.process( @wfid )
      @nada_exp_id = process.expressions.last.fei.expid

      @nada_exp_id.should_not be_nil
    end

    it "should return it (HTML)" do
      get "/workitems/#{@wfid}/#{@nada_exp_id}"

      last_response.should be_ok
    end

    it "should return it (JSON)" do
      get "/workitems/#{@wfid}/#{@nada_exp_id}.json"

      last_response.should be_ok
    end
  end

  describe "without a workitem" do
    it "should return a 404 (HTML)" do
      get "/workitems/foo/bar"

      last_response.should_not be_ok
      last_response.status.should be(404)
    end

    it "should return a 404 (JSON)" do
      get "/workitems/foo/bar.json"

      last_response.should_not be_ok
      last_response.status.should be(404)
    end
  end
end

describe "PUT /workitems/X-Y" do
  before(:each) do
    @wfid = launch_test_process do
      Ruote.process_definition :name => 'foo' do
        sequence do
          nada :activity => 'Work your magic'
        end
      end
    end

    process = RuoteKit.engine.process( @wfid )
    @nada_exp_id = process.expressions.last.fei.expid

    @nada_exp_id.should_not be_nil
  end

  it "should update the workitem fields (HTML)" do
    fields = {
      "activity" => "Work your magic",
      "foo" => "bar"
    }.to_json

    put "/workitems/#{@wfid}/#{@nada_exp_id}", :fields => fields

    last_response.should be_redirect
    last_response['Location'].should == "/workitems/#{@wfid}/#{@nada_exp_id}"

    find_workitem( @wfid, @nada_exp_id ).fields.should == fields
  end

  it "should update the workitem fields (JSON)" do
    params = {
        "fields" => {
        "activity" => "Work your magic",
        "foo" => "bar"
      }
    }

    put "/workitems/#{@wfid}/#{@nada_exp_id}", params.to_json, { 'CONTENT_TYPE' => 'application/json' }

    last_response.should be_ok
  end

  it "should reply to the engine (HTML)"
  it "should reply to the engine (JSON)"
end
