# see observer_controller.rb
class ObserverController
  helper SuggestionsHelper
  def suggestions # :norobots:
    @observation = find_or_goto_index(Observation, params[:id].to_s)
    @suggestions = Suggestion.analyze(JSON.parse(params[:names].to_s))
  end
end
