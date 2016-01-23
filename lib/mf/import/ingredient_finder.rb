module MF::Import::IngredientFinder
  def get_ingredient_groups
    # First try with depth 3.
    groups = get_ingredient_groups_with_depth(3)
    
    # See if any groups are suspiciously long.
    if groups.select{|g| g[:name].length > 100}.length > 0
      return get_ingredient_groups_with_depth(2)
    else
      return groups
    end
  end
end