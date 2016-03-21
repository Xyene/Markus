module Api

  # Allows for pushing and downloading of TestResults
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TestResultsController < MainApiController

    # Returns a list of TesResults associated with a group's assignment submission
    # Requires: assignment_id, group_id, test script result id
    # Optional: filter, fields
    def index
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_results = submission.test_script_results
                  .includes(:test_results)
                  .find_by_id(params[:test_script_result_id])
                  .test_results

      respond_to do |format|
        format.xml{render xml: test_results.to_xml(root:
          'test_results', skip_types: 'true')}
        format.json{render json: test_results.to_json}
      end
    end

    # Sends the contents of the specified Test Result
    # Requires: assignment_id, group_id, test_script_result id, id
    def show
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_result = submission.test_script_results
                            .includes(:test_results)
                            .find_by_id(params[:test_script_result_id])
                            .test_results.find_by_id(params[:id])
     
      if test_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test script result was not found'}, status: 404
        return
      end

      respond_to do |format|
        format.xml{render xml: test_result.to_xml(root:
          'test_result', skip_types: 'true')}
        format.json{render json: test_result.to_json}
      end
    end

    # Creates a new test result for a group's latest assignment submission
    # Requires:
    #  - assignment_id
    #  - group_id
    #  - file_content: Contents of the test results file to be uploaded
    def create
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_script_result = submission.test_script_results
                            .includes(:test_results)
                            .find_by_id(params[:test_script_result_id])
      if test_script_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test script result was not found'}, status: 404
        return
      end

      if test_script_result.test_results.create!(user_params)
        render 'shared/http_status', locals: {code: '201', message:
          HttpStatusHelper::ERROR_CODE['message']['201']}, status: 201
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Deletes a Test Result instance
    # Requires: assignment_id, group_id, test script result id, id
    def destroy
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_result = submission.test_script_results
                            .includes(:test_results)
                            .find_by_id(params[:test_script_result_id])
                            .test_results.find_by_id(params[:id])
     
      if test_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test result was not found'}, status: 404
        return
      end

      if test_result.destroy
        # Successfully deleted the TestResult; render success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Updates a TestResult instance
    # Requires: assignment_id, group_id, id
    # Optional:
    #  - filename: New name for the file
    #  - file_content: New contents of the test results file
    def update
            # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_result = submission.test_script_results
                            .includes(:test_results)
                            .find_by_id(params[:test_script_result_id])
                            .test_results.find_by_id(params[:id])
     
      if test_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test script result was not found'}, status: 404
        return
      end

      # Update filename if provided
      test_result.update_attributes(user_params)

      if test_result.save
        # Everything went fine; report success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # User params for create & update
    def user_params
      params.permit(:name, :completion_status, :marks_earned, :repo_revision,
                    :input, :actual_output, :expected_output, :created_at,
                    :updated_at)
    end

    # Given assignment and group id's, returns the submission if found, or nil
    # otherwise. Also renders appropriate responses on error.
    def get_submission(assignment_id, group_id)
      assignment = Assignment.find_by_id(assignment_id)
      if assignment.nil?
        # No assignment with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return nil
      end

      group = Group.find_by_id(group_id)
      if group.nil?
        # No group exists with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No group exists with that id'}, status: 404
        return nil
      end

      submission = Submission.get_submission_by_group_and_assignment(
        group[:group_name], assignment[:short_identifier])
      if submission.nil?
        # No assignment submission by that group
        render 'shared/http_status', locals: {code: '404', message:
          'Submission was not found'}, status: 404
      end

      submission
    end

  end # end TestResultsController
end
