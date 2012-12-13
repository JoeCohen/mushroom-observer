require File.expand_path(File.dirname(__FILE__) + '/../boot')

class SpecimenControllerTest < FunctionalTestCase
  def test_show_specimen
    specimen = specimens(:coprinus_comatus_nybg_spec)
    assert(specimen)
    get_with_dump(:show_specimen, :id => specimen.id)
    assert_response('show_specimen')
  end

  def test_herbarium_index
    get_with_dump(:herbarium_index, :id => herbaria(:nybg).id)
    assert_response('specimen_index')
  end

  def test_herbarium_with_one_specimen_index
    get_with_dump(:herbarium_index, :id => herbaria(:rolf).id)
    assert_response(:redirect)
    assert_no_flash
  end

  def test_herbarium_with_no_specimens_index
    get_with_dump(:herbarium_index, :id => herbaria(:dick).id)
    assert_response(:redirect)
    assert_flash(/no specimens/)
  end

  def test_observation_index
    get_with_dump(:observation_index, :id => observations(:coprinus_comatus_obs).id)
    assert_response('specimen_index')
  end

  def test_observation_with_one_specimen_index
    get_with_dump(:observation_index, :id => observations(:detailed_unknown).id)
    assert_response(:redirect)
    assert_no_flash
  end

  def test_observation_with_no_specimens_index
    get_with_dump(:observation_index, :id => observations(:strobilurus_diminutivus_obs).id)
    assert_response(:redirect)
    assert_flash(/no specimens/)
  end
  
  def test_add_specimen
    get(:add_specimen, :id => observations(:coprinus_comatus_obs).id)
    assert_response(:redirect)

    login('rolf')
    get_with_dump(:add_specimen, :id => observations(:coprinus_comatus_obs).id)
    assert_response('add_specimen')
    assert(assigns(:herbarium_label))
  end
 
  def add_specimen_params
    return {
      :id => observations(:strobilurus_diminutivus_obs).id,
      :specimen => {
        :herbarium_name => users(:rolf).preferred_herbarium_name,
        :herbarium_label => "Strobilurus diminutivus det. Rolf Singer - NYBG 1234567",
        'when(1i)'      => '2012',
        'when(2i)'      => '11',
        'when(3i)'      => '26',
        :notes => "Some notes about this specimen"
      }
    }
  end
  
  def test_add_specimen_post
    login('rolf')
    specimen_count = Specimen.count
    params = add_specimen_params
    obs = Observation.find(params[:id])
    assert(!obs.specimen)
    post(:add_specimen, params)
    assert_equal(specimen_count + 1, Specimen.count)
    specimen = Specimen.find(:all, :order => "created_at DESC")[0]
    assert_equal(params[:specimen][:herbarium_name], specimen.herbarium.name)
    assert_equal(params[:specimen][:herbarium_label], specimen.herbarium_label)
    assert_equal(params[:specimen]['when(1i)'].to_i, specimen.when.year)
    assert_equal(params[:specimen]['when(2i)'].to_i, specimen.when.month)
    assert_equal(params[:specimen]['when(3i)'].to_i, specimen.when.day)
    assert_equal(users(:rolf), specimen.user)
    obs = Observation.find(params[:id])
    assert(obs.specimen)
    assert_response(:redirect)
  end
  
  def test_add_specimen_post_new_herbarium
    mary = login('mary')
    herbarium_count = mary.curated_herbaria.count
    # Count the number of herbaria that mary is a curator for
    params = add_specimen_params
    params[:specimen][:herbarium_name] = mary.preferred_herbarium_name
    post(:add_specimen, params)
    mary = User.find(mary.id) # Reload user
    assert_equal(herbarium_count+1, mary.curated_herbaria.count)
    herbarium = Herbarium.find(:all, :order => "created_at DESC")[0]
    assert(herbarium.curators.member?(mary))
  end
  
  def test_add_specimen_post_duplicate
    login('rolf')
    specimen_count = Specimen.count
    params = add_specimen_params
    existing_specimen = specimens(:coprinus_comatus_nybg_spec)
    params[:specimen][:herbarium_name] = existing_specimen.herbarium.name
    params[:specimen][:herbarium_label] = existing_specimen.herbarium_label
    post(:add_specimen, params)
    assert_equal(specimen_count, Specimen.count)
    assert_flash(/already exists/i)    
    assert_response(:success)
  end
  
  # I keep thinking only curators should be able to add specimens...
  def test_add_specimen_post_not_curator
    user = login('mary')
    nybg = herbaria(:nybg)
    assert(!nybg.curators.member?(user))
    specimen_count = Specimen.count
    herbarium_count = Herbarium.count
    params = add_specimen_params
    params[:specimen][:herbarium_name] = nybg.name
    post(:add_specimen, params)
    nybg = Herbarium.find(nybg.id) # Reload herbarium
    assert(!nybg.curators.member?(user))
    assert_equal(specimen_count + 1, Specimen.count)
    assert_response(:redirect)
  end

  def test_edit_specimen
    nybg = specimens(:coprinus_comatus_nybg_spec)
    get_with_dump(:edit_specimen, :id => nybg.id)
    assert_response(:redirect)

    login('mary') # Non-curator
    get_with_dump(:edit_specimen, :id => nybg.id)
    assert_flash(/without permission/i)
    assert_response(:redirect)

    login('rolf')
    get_with_dump(:edit_specimen, :id => nybg.id)
    assert_response('edit_specimen')
  end
  
  def test_edit_specimen_post
    login('rolf')
    nybg = specimens(:coprinus_comatus_nybg_spec)
    herbarium = nybg.herbarium
    user = nybg.user
    params = add_specimen_params
    params[:id] = nybg.id
    post(:edit_specimen, params)
    specimen = Specimen.find(nybg.id)
    assert_equal(herbarium, specimen.herbarium)
    assert_equal(user, specimen.user)
    assert_equal(params[:specimen][:herbarium_label], specimen.herbarium_label)
    assert_equal(params[:specimen]['when(1i)'].to_i, specimen.when.year)
    assert_equal(params[:specimen]['when(2i)'].to_i, specimen.when.month)
    assert_equal(params[:specimen]['when(3i)'].to_i, specimen.when.day)
    assert_equal(params[:specimen][:notes], specimen.notes)
    assert_equal(nybg.user, specimen.user)
    assert_response(:redirect)
  end
end
