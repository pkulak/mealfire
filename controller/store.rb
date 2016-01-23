class StoreController < Controller
  def new
    if request[:id]
      @store = Store[request[:id]].required
      
      unless @store.user_id == current_user.id
        raise UserException.new("That is not your store.")
      end
      
      @categories = @store.categories
    else
      @categories = Category.all
    end
    
    if request.post?
      if request[:store_name].blank?
        flash.previous[:notice] = ["Name Required", "Please enter a name for your new store."]
        @categories.sort_by_ids(request[:category_order].split(',').collect{|id| id.to_i})
        return
      end
      
      if @store
        @store.categories = request[:category_order]
        @store.name = request[:store_name]
        @store.save
        
        flash[:notice] = ["Store Edited", "The store has been edited."]
        redirect '/store'
      else
        Store.create(
          user_id: current_user.id,
          categories: request[:category_order],
          name: request[:store_name])
        
        flash[:notice] = ["Store Created", "The store has been created."]
        redirect '/store'
      end
    end
  end
  
  def edit
    @store = Store[request[:id]].required
    @categories = @store.categories
    'store/new'
  end
  
  def delete
    @store = Store[request[:id]].required
    return 'Error' unless @store.user == current_user
    @store.destroy
    'OK'
  end
end