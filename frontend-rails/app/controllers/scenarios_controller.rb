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
  # POST /scenarios.json
  
  
  def create
    @scenario = Scenario.new(scenario_params)
    begin
        @scenario.push
        render json: @scenario
    rescue StandardError => ex
        render json: @scenario.errors, status: :unprocessable_entity
    end
  end
  
  def create_results
      batch = scenario_params[:batch]
      sequence_no = scenario_params[:sequence_no]
      @scenario = Scenario.new(scenario_params)
      redis_key = "scenarios:#{batch}:#{sequence_no}"
      $redis.set(redis_key, @scenario.to_json)
      $redis.expire(redis_key, 3.hours)
      
      render json: @scenario
  end
  
  def get_results 
      batch = scenario_params[:batch]
      sequence_no = scenario_params[:sequence_no]
      @scenario = JSON.parse($redis.get("scenarios:#{batch}:#{sequence_no}"))
      render json: @scenario
  end
  
  def sns
      sns_message_type = request.headers['x-amz-sns-message-type']

      request_json = JSON.parse(request.raw_post, {symbolize_names: true})
      message_id = request_json[:MessageId]
      
     
      #Prevent duplicate Notification. Do not process if message ID is known already.
      #Non-duplication window is 30 minutes
      redis_key = "scenarios:sns:#{message_id}"
      
      if ($redis.get(redis_key).nil?)
        $redis.set(redis_key, true)
        $redis.expire(redis_key, 30.minutes)
      
        #begin processing
        logger.debug "Message ID: #{message_id}"
        logger.debug "SNS Message Type: #{sns_message_type}"
        logger.debug request.raw_post      
          
          
        case sns_message_type
        when "Notification"
        when "SubscriptionConfirmation"
            subscribe_url = request_json[:SubscribeURL]
            #TODO: Manual subscription for now
        end
     else
         logger.debug "Message ID #{message_id} is duplicate. ignore."
     end
          
      
      #logger.debug subscribe_url
      #redirect_to subscribe_url
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
      params    #whitelist later.
    end
end
