class OrdersPluginConsumerController < ProfileController

  no_design_blocks

  before_filter :login_required, :except => [:index, :edit]
  before_filter :load_order, :except => [:new]
  before_filter :check_access, :only => [:confirm, :remove, :cancel]

  def confirm
    params[:order] ||= {}

    if @order.items.size > 0
      @order.update_attributes! params[:order].merge(:status => 'confirmed')
      OrdersPlugin::Mailer.deliver_order_confirmation @order, request.host_with_port
      session[:notice] = t('orders_plugin.controllers.profile.consumer.order_confirmed')
    else
      session[:notice] = t('orders_plugin.controllers.profile.consumer.can_not_confirm_your_')
    end

    redirect_to :action => :edit, :id => @order.id
  end

  def cancel
    @order.update_attributes! :status => 'cancelled'
    OrdersPlugin::Mailer.deliver_order_cancellation @order
    session[:notice] = t('orders_plugin.controllers.profile.consumer.order_cancelled')
  end

  protected

  def load_order
    @order = OrdersPlugin::Order.find_by_id params[:id]
    render_access_denied if @order.present? and not @order.may_view? user
  end

  def check_access access = 'view'
    unless @order.send "may_#{access}?", user
      session[:notice] = if user.blank? then t('orders_plugin.controllers.profile.consumer.login_first') else session[:notice] = t('orders_plugin.controllers.profile.consumer.you_are_not_the_owner') end
      redirect_to :action => :index
      false
    else
      true
    end
  end

end
