class DefenceRequestForm
  include ActiveModel::Model

  attr_reader :defence_request, :fields

  def self.model_name
    ActiveModel::Name.new(self, nil, 'DefenceRequest')
  end

  def initialize(defence_request)
    @fields = {}
    @defence_request = defence_request
    register_field :date_of_birth, DateField
    register_field :time_of_arrival, DateTimeField
    register_field :solicitor_time_of_arrival, DateTimeField
    register_field :interview_start_time, DateTimeField
    register_field :solicitor, SolicitorField
    register_field :appropriate_adult, AppropriateAdultField
  end

  def register_field field_name, klass, opts={}
    @fields[field_name] = klass.from_persisted_value @defence_request.send field_name
  end

  delegate :solicitor_type, :solicitor_name, :solicitor_firm, :phone_number, :detainee_name,
           :gender, :detainee_age, :allegations, :scheme, :custody_number, :comments, :feedback,
           to: :defence_request

  def submit(params)
    @fields.select!{ |k, v| params.include?(k) }

    params_without_fields =  params.reject { |k, _| @fields.keys.include? k.to_sym}
    @defence_request.assign_attributes params_without_fields

    @fields.dup.each do |field_name, field_value|
      field_value = field_value.class.new params[field_name]
      @fields[field_name] = field_value
      @defence_request.assign_attributes({ field_name => field_value.value })
    end

    if @fields.all?(&valid_if_present?) & @defence_request.valid?
      @defence_request.save!
      true
    else
      add_errors_to_form
      false
    end
  end

  def add_errors_to_form
    @defence_request.errors.messages.each do |field_name, error_message|
      self.errors[field_name] = error_message.join ", "
    end

    @fields.map(&:to_a).reject(&valid_if_present?).each do |field_name, field_value|
      if field_value.present?
        self.errors[field_name].clear
        self.errors[field_name] = field_value.errors.full_messages.join ", "
      end
    end
  end

  def valid_if_present?
    ->(field) do
      field_value = field.last
      field_value.valid? || field_value.blank?
    end
  end
end
