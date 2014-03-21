# workaround for plugin class scope problem
require_dependency 'orders_cycle_plugin/display_helper'
OrdersCyclePlugin::OrdersCycleDisplayHelper = OrdersCyclePlugin::DisplayHelper
require_dependency 'suppliers_plugin/product_helper'

class OrdersCyclePluginOrderController < OrdersPluginConsumerController

  # FIXME: remove me when styles move from consumers_coop plugin
  include ConsumersCoopPlugin::ControllerHelper
  include OrdersCyclePlugin::TranslationHelper

  no_design_blocks
  before_filter :login_required, :except => [:index]

  helper OrdersCyclePlugin::OrdersCycleDisplayHelper
  helper SuppliersPlugin::ProductHelper
  helper OrdersCyclePlugin::TranslationHelper

  def index
    @current_year = DateTime.now.year.to_s
    @year = (params[:year] || @current_year).to_s

    @years_with_cycles = profile.orders_cycles_without_order.years.collect &:year
    @years_with_cycles.unshift @current_year unless @years_with_cycles.include? @current_year

    @cycles = profile.orders_cycles.by_year @year
    @consumer = user
  end

  def new
    if user.blank?
      session[:notice] = t('orders_plugin.controllers.profile.consumer.please_login_first')
      redirect_to :action => :index
      return
    end

    @consumer = user
    @cycle = OrdersCyclePlugin::Cycle.find params[:cycle_id]
    @order = OrdersPlugin::Order.create! :profile => profile, :consumer => @consumer, :cycle => @cycle
    redirect_to params.merge(:action => :edit, :id => @order.id)
  end

  def edit
    if cycle_id = params[:cycle_id]
      @cycle = OrdersCyclePlugin::Cycle.find_by_id cycle_id
      return render_not_found unless @cycle
      @consumer = user
    else
      return render_not_found unless @order
      @admin_edit = user and user != @consumer
      @consumer = @order.consumer
      @cycle = @order.cycle
      @consumer_orders = @cycle.orders.for_consumer @consumer

      render 'consumer_orders' if params[:consumer_orders]
    end
    @products = @cycle.products_for_order
    @product_categories = Product.product_categories_of @products
    @consumer_orders = @cycle.orders.for_consumer @consumer

    render 'consumer_orders' if params[:consumer_orders]
  end

  def cancel
    super
    redirect_to :action => :index, :cycle_id => @order.cycle.id
  end

  def remove
    super
    redirect_to :action => :index, :cycle_id => @order.cycle.id
  end

  def reopen
    @order = OrdersPlugin::Order.find params[:id]
    if @order.consumer == user
      raise "Cycle's orders period already ended" unless @order.cycle.orders?
      @order.update_attributes! :status => 'draft'
    end

    redirect_to :action => :edit, :id => @order.id
  end

  def confirm
    raise "Cycle's orders period already ended" unless @order.cycle.orders?
    super
  end

  def admin_new
    return redirect_to :action => :index unless profile.has_admin? user

    @consumer = user
    @cycle = OrdersCyclePlugin::Cycle.find params[:cycle_id]
    @order = OrdersPlugin::Order.create! :cycle => @cycle, :consumer => @consumer
    redirect_to :action => :edit, :id => @order.id, :profile => profile.identifier
  end

  def cycle_edit
    @order = OrdersPlugin::Order.find params[:id]
    return unless check_access 'edit'

    if @order.cycle.orders?
      a = {}; @order.items.map{ |p| a[p.id] = p }
      b = {}; params[:order][:items].map do |key, attrs|
        p = OrdersPlugin::Item.new attrs
        p.id = attrs[:id]
        b[p.id] = p
      end

      removed = a.values.map do |p|
        p if b[p.id].nil?
      end.compact
      changed = b.values.map do |p|
        pa = a[p.id]
        if pa and p.quantity_asked != pa.quantity_asked
          pa.quantity_asked = p.quantity_asked
          pa
        end
      end.compact

      changed.each{ |p| p.save! }
      removed.each{ |p| p.destroy }
    end

    if params[:warn_consumer]
      message = (params[:include_message] and !params[:message].blank?) ? params[:message] : nil
      OrdersCyclePlugin::Mailer.deliver_order_change_notification profile, @order, changed, removed, message
    end

  end

  def filter
    @cycle = OrdersCyclePlugin::Cycle.find params[:cycle_id]
    @order = OrdersPlugin::Order.find_by_id params[:order_id]

    scope = @cycle.products_for_order
    @products = SuppliersPlugin::BaseProduct.search_scope(scope, params).sources_from_2x_products_joins.all

    render :partial => 'filter', :locals => {
      :order => @order, :cycle => @cycle,
      :products_for_order => @products,
    }
  end

  def render_delivery
    @order = OrdersPlugin::Order.find params[:id]
    @order.attributes = params[:order]
    render :partial => 'delivery', :layout => false, :locals => {:order => @order}
  end

  def supplier_balloon
    @supplier = SuppliersPlugin::Supplier.find params[:id]
    render :layout => false
  end
  def product_balloon
    @product = OrdersCyclePlugin::OfferedProduct.find params[:id]
    render :layout => false
  end

  protected

  include ControllerInheritance
  replace_url_for self.superclass => self

end
