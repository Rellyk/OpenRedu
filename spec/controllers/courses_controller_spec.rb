require 'spec_helper'
require 'authlogic/test_case'

describe CoursesController do
  context "when creating a course for an existing environment" do
    before do
      @user = Factory(:user)
      activate_authlogic
      UserSession.create @user

      @environment = Factory(:environment, :owner => @user)

      @params = {:course =>
        { :name => "Redu", :workload => 12,
          :tag_list => "minhas, tags, exemplo, aula, teste",
          :path => "redu", :subscription_type => 1,
          :description => "Lorem ipsum dolor sit amet, consectetur magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation
        ullamco laboris nisi ut aliquip ex ea commodo."},
        :plan => "free",
        :environment_id => @environment.id,
        :locale => "pt-BR" }
    end

    context "POST create" do
      before do
        post :create, @params
      end

      it "should create the course" do
        assigns[:course].should_not be_nil
        assigns[:course].should be_valid
      end

      it "should create the plan" do
        assigns[:course].plan.should_not be_nil
      end

      it "should assign the plan user to current_user" do
        assigns[:course].plan.user.should == @user
      end

      it "should create the quota and computes it" do
        assigns[:course].quota.should_not be_nil
      end
    end

  end

  context "when viewing existent courses list" do
    before do
      @courses = (1..10).collect { Factory(:course) }
      @audiences = (1..5).collect { Factory(:audience) }

      @courses[0..3].each_with_index do |c, i|
        c.audiences << @audiences[i] << @audiences[i+1]
      end

      @courses[4..7].each_with_index do |c, i|
        c.audiences << @audiences.reverse[i] << @audiences.reverse[i+1]
      end
    end

    context "GET index" do
      before do
        get :index, :locale => 'pt-BR'
      end

      it "should assign all courses" do
        assigns[:courses].should_not be_nil
        assigns[:courses].to_set.
          should == Course.published.all(:limit => 10).to_set
      end

      it "should render courses/new/index" do
        response.should render_template('courses/new/index')
      end
    end

    context "where the user is" do
      before  do
        User.maintain_sessions = false
        @user = Factory(:user)
        activate_authlogic
        UserSession.create @user

        @courses[0].join @user
        @courses[5].join @user
        @courses[1..3].each { |c| c.join @user, Role[:tutor] }
        @courses[6].join @user, Role[:teacher]
        @courses[7].join @user, Role[:environment_admin]

      end

      context "student" do
        before do
          get :index, :locale => 'pt-BR', :role => 'student'
        end

        it "should assign all these courses" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == [@courses[0], @courses[5]].to_set
        end

        it "should render courses/new/index" do
          response.should render_template('courses/new/index')
        end
      end

      context "tutor" do
        before do
          get :index, :locale => 'pt-BR', :role => 'tutor'
        end

        it "should assign all these courses" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == @courses[1..3].to_set
        end

        it "should render courses/new/index" do
          response.should render_template('courses/new/index')
        end
      end

      context "teacher" do
        before do
          get :index, :locale => 'pt-BR', :role => 'teacher'
        end

        it "should assign all these courses" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == [@courses[6]].to_set
        end

        it "should render courses/new/index" do
          response.should render_template('courses/new/index')
        end
      end

      context "administrator" do
        before do
          get :index, :locale => 'pt-BR', :role => 'administrator'
        end

        it "should assign all these courses" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == [@courses[7]].to_set
        end

        it "should render courses/new/index" do
          response.should render_template('courses/new/index')
        end
      end
    end

    context "GET index with js format" do
      before do
        get :index, :locale => 'pt-BR', :format =>'js'
      end

      it "should assign all courses" do
        assigns[:courses].should_not be_nil
        assigns[:courses].to_set.
          should == Course.published.all(:limit => 10).to_set
      end

      it "should render courses/new/index" do
        response.should render_template('courses/new/index')
      end
    end

    context "POST index" do
      context "with specified audiences" do
        before do
          post :index, :locale => 'pt-BR',
            :audiences_ids => [@audiences[0].id, @audiences[3].id]
        end

        it "should assign all courses with one of specified audiences" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == Course.
            with_audiences([@audiences[0].id, @audiences[3].id]).to_set
        end
      end

      context "with specified keyword" do
        before  do
          @c1 = Factory(:course, :name => 'keyword')
          @c2 = Factory(:course, :name => 'another key')
          @c3 = Factory(:course, :name => 'key 2')
          post :index, :locale => 'pt-BR', :search => 'key'
        end

        it "should assign all courses with name LIKE the keyword" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == [@c1, @c2, @c3].to_set
        end
      end

      context "with specified audiences AND with specified keyword" do
        before  do
          @c1 = Factory(:course, :name => 'keyword')
          @c2 = Factory(:course, :name => 'another key')
          @c3 = Factory(:course, :name => 'key 2')
          @a1 = Factory(:audience)
          @a2 = Factory(:audience)

          @c1.audiences << @a1
          @c2.audiences << @a1 << @a2
          post :index, :locale => 'pt-BR', :search => 'key',
            :audiences_ids => [@a1.id, @a2.id]
        end

        it "should assign all courses with one of specified audience AND name LIKE the keyword" do
          assigns[:courses].should_not be_nil
          assigns[:courses].to_set.should == [@c1, @c2].to_set
        end
      end
    end
  end
end