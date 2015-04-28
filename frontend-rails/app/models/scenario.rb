class Scenario
    
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    
    @@readonly_attributes = :batch, :sequence_no, :ref_no, :test_date, 
        :description, :keyword, :a_number, 
        :b_number, :expected_result, :time_sent, :time_received,
        :beginning_balance, :ending_balance, :amount_charged,
        :actual_result, :pass_or_fail, :remarks, :ussd_command,
        :ussd_number
    @@attributes = @@readonly_attributes
    
    @@attributes.each do |attr|
        attr_reader attr.to_sym
    end

    #Validation errors    
    attr_reader :errors
    
    def initialize(params = {})
        
        @@attributes.each do |attr|
            instance_variable_set("@#{attr}", params[attr.to_sym])
        end

        #Amazon-related settings. remove hardcoded settings later.
        @sqs = Aws::SQS::Client.new(region: 'ap-southeast-1')
        @sqs_url = "https://sqs.ap-southeast-1.amazonaws.com/119554206391/lost_treasure" 
        

        @errors = []
    end
    
    
    def as_json(options)
        {
            batch: batch,
            sequence_no: sequence_no,
            ref_no: ref_no,
            test_date: test_date,
            description: description,
            keyword: keyword,
            a_number: a_number,
            b_number: b_number,
            time_sent: time_sent,
            time_received: time_received,
            beginning_balance: beginning_balance,
            ending_balance: ending_balance,
            amount_charged: amount_charged,
            expected_result: expected_result,
            actual_result: actual_result,
            pass_or_fail: pass_or_fail,
            remarks: remarks,
            ussd_command: ussd_command,
            ussd_number: ussd_number
        }
    end
    
    def push
         if validates?
             response = @sqs.send_message(queue_url: @sqs_url, 
                    message_body: to_json )
        else
            throw StandardError.new(@errors.join("\n"))
        end
        end
    
    def validates?
        @errors = []
        does_validate = true
        
        #Sequence numbers are required to be able to get the appropriate response
        (@errors << "Batch (batch) is required."; does_validate = false)  if batch.blank?
        (@errors << "Sequence Number (sequence_no) is required."; does_validate = false)  if sequence_no.blank?
        
        #Can't make the thing work without these
        (@errors << "Keyword (keyword) is required."; does_validate = false)  if keyword.blank?
        (@errors << "A Number (a_number) is required."; does_validate = false)  if a_number.blank?
        (@errors << "B Number (b_number) is required."; does_validate = false)  if b_number.blank?
        (@errors << "Expected result (expected_result) is required."; does_validate = false)  if expected_result.blank?
        
        does_validate
    end    
    
end
