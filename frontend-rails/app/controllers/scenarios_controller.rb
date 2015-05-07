class ScenariosController < ApplicationController
  before_action :set_scenario, only: [:show, :edit, :update, :destroy]

  # GET /scenarios
  # GET /scenarios.json
  #def index
  #  @scenarios = Scenario.all
  #end

  # GET /scenarios/1
  # GET /scenarios/1.json
  #def show
  #end

  # GET /scenarios/new
  #def new
  #  @scenario = Scenario.new
  #end

  # GET /scenarios/1/edit
  #def edit
  #end

  # POST /scenarios
  #  POST /scenarios.json

  def get_all
    @scenarios = Scenario.all
    render json: { success: true, scenarios: @scenarios }
  end
  
  def import_csv
    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Accept"] = "text/csv"

    if not params[:file].nil?
      scenarios = Scenario.import(params[:file])
    end
    render json: {:success => true, scenarios: scenarios}
  end

  def create
    @scenario = Scenario.new(scenario_params)
    begin
        @scenario.push
        render json: @scenario
    rescue StandardError => ex
        render json: @scenario.errors.messages, status: :unprocessable_entity
    end
  end
  
  #def create_results
  #    batch = scenario_params[:batch]
  #    sequence_no = scenario_params[:sequence_no]
  #    @scenario = Scenario.new(scenario_params)
  #    redis_key = "scenarios:#{batch}:#{sequence_no}"
  #    $redis.set(redis_key, @scenario.to_json)
  #    $redis.expire(redis_key, 3.hours)
  #    
  #    render json: @scenario
  #end
  
  def get_results 
      batch = params[:batch]
      sequence_no = params[:sequence_no]
      result = $redis.get("scenarios:#{batch}:#{sequence_no}")
      if !result.nil?
        @scenario = JSON.parse(result, {symbolize_names: true})
        render json: @scenario
      else
         render status: :not_found, json: {}
      end
  end
  
  def sns
        sns_message_type = request.headers['x-amz-sns-message-type']

        request_json = JSON.parse(request.raw_post, {symbolize_names: true})
      
        #begin processing
        logger.debug "SNS Message Type: #{sns_message_type}"
        logger.debug request.raw_post      
          
        case sns_message_type
        when "Notification"
          batch = request_json[:batch]
          sequence_no = request_json[:sequence_no]
          @scenario = Scenario.new(request_json)
          redis_key = "scenarios:#{batch}:#{sequence_no}"
          $redis.set(redis_key, @scenario.to_json)
          $redis.expire(redis_key, 3.hours)            
                
        when "SubscriptionConfirmation"
            message_id = request_json[:MessageId]
            subscribe_url = request_json[:SubscribeURL]
            #TODO: Manual subscription for now
        end
  
      render json: {}
  end

  # PATCH/PUT /scenarios/1
  # PATCH/PUT /scenarios/1.json
  #def update
  #  respond_to do |format|
  #    if @scenario.update(scenario_params)
  #      format.html { redirect_to @scenario, notice: 'Scenario was successfully updated.' }
  #      format.json { render :show, status: :ok, location: @scenario }
  #    else
  #      format.html { render :edit }
  #      format.json { render json: @scenario.errors, status: :unprocessable_entity }
  #    end
  #  end
  #end

  # DELETE /scenarios/1
  # DELETE /scenarios/1.json
  #def destroy
  #  @scenario.destroy
  #  respond_to do |format|
  #    format.html { redirect_to scenarios_url, notice: 'Scenario was successfully destroyed.' }
  #    format.json { head :no_content }
  #  end
  #end

  #private
    # Use callbacks to share common setup or constraints between actions.
  #  def set_scenario
  #    @scenario = Scenario.find(params[:id])
  #  end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scenario_params
      params.require(:scenario).permit(:batch, :sequence_no, :ref_no, :test_date, :description,
                                       :keyword, :sender, :recipient, :expected_result, :time_sent,
                                       :time_received, :beginning_balance, :ending_balance, :amount_charged,
                                       :actual_result, :pass_or_fail, :remarks, :ussd_command, :ussd_number,
                                       :test_type, :operation, :expected_charge, :run_time, :number_of_tries,
                                       :condition, :status)
    end
end
