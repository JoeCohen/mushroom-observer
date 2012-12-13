class Herbarium < AbstractModel
  has_many :specimens
  belongs_to :location
  has_and_belongs_to_many :curators, :class_name => "User", :join_table => "herbaria_curators"
  
  # Used to allow location name to be entered as text in forms
  attr_accessor :place_name

  def is_curator?(user)
    user and curators.member?(user)
  end

  def label_free?(new_label)
    Specimen.find_all_by_herbarium_id_and_herbarium_label(self.id, new_label).count == 0
  end
  
  def self.default_specimen_label(name, id)
    "#{name}: #{id || '?'}".strip_html
  end

  # Look at the most recent Specimen's the current User has created.  Return
  # a list of the last 100 herbarium names used in those Specimens that this user
  # is a curator for.  This list is used to prime Herbarium auto-completers.
  #
  def self.primer
    result = ''
    if User.current
      result = self.connection.select_values(%(
        SELECT DISTINCT h.name AS x
        FROM specimens s, herbaria h, herbaria_curators c
        WHERE s.herbarium_id = h.id
        AND h.id = c.herbarium_id
        AND c.user_id = #{user_id}
        ORDER BY s.modified DESC
        LIMIT 100
      )).sort
    end
    result
  end
end
