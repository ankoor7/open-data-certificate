class ResponseSet < ActiveRecord::Base
  unloadable
  include Surveyor::Models::ResponseSetMethods

  attr_accessible :dataset_id

  belongs_to :dataset
  belongs_to :survey

  def title
    responses.joins(:question).where('questions.reference_identifier == ?', 'dataTitle').first.try(:string_value) || 'Untitled'
  end

  def incomplete!
    update_attribute :completed_at, nil
  end

  def triggered_mandatory_questions
    @triggered_mandatory_questions ||= self.survey.mandatory_questions.select{|q|q.triggered?(self)}
  end

  def triggered_requirements
    @triggered_requirements ||= survey.requirements.select{|r|r.triggered?(self)}
  end

  def attained_level
    Survey::REQUIREMENT_LEVELS[minimum_attained_requirement_level-1]
  end

  def minimum_attained_requirement_level
    (outstanding_requirements.map(&:requirement_level_index) << Survey::REQUIREMENT_LEVELS.size).min
  end

  def completed_requirements
    @completed_requirements ||= triggered_requirements.select{|r|r.requirement_met_by_responses?(self.responses)}
  end

  def outstanding_requirements
    triggered_requirements - completed_requirements
  end

end
