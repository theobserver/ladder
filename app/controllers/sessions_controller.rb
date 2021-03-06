class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:callback]

  def new
    @authhash = session['authhash']
    redirect_to session_path unless @authhash
  end

  def show
  end

  def create
    @authhash = session['authhash']
    if params[:commit] =~ /cancel/i
      reset_session
      redirect_to session_path, :notice => t('sessions.create.canceled', :provider => @authhash['provider'].humanize)
    else
      @user = User.new(:name => @authhash['name'], :email => @authhash['email'])
      @service = @user.build_preferred_service(@authhash)
      if @user.save && @service.update_attributes(:user_id => @user.id)
        authenticate_and_redirect(@user, @service)
      else
        redirect_to session_path, :notice => t('sessions.create.unknown')
      end
    end
  end

  def destroy
    reset_session
    redirect_to root_path, :notice => t('sessions.destroy.success')
  end

  def callback
    omniauth = request.env['omniauth.auth']
    @authhash = {
      'provider' => omniauth['provider'],
      'uid' => omniauth['uid'],
      'name' => omniauth['info']['name'],
      'email' => omniauth['info']['email'],
      'first_name' => omniauth['info']['first_name'],
      'last_name' => omniauth['info']['last_name'],
      'image_url' => omniauth['info']['image'],
    }
    session['authhash'] = @authhash
    auth = Service.find_by_provider_and_uid(@authhash['provider'], @authhash['uid'])
    if auth && auth.update_attributes(@authhash)
      authenticate_and_redirect(auth.user, auth)
    else
      render :new
    end
  end

  def failure
    reset_session
    redirect_to session_path, :notice => case params[:message]
    when /invalid_credentials/i
      t('sessions.failure.invalid')
    when /timeout/i
      t('sessions.failure.timed_out')
    else
      t('sessions.failure.unknown')
    end
  end

  def google
    if !request.headers['X-Requested-With']
      redirect_to auth_failure_path
      return
    end

    authenticator = GoogleAuthenticator.new
    profile = authenticator.fetch_profile(params['code'], redirect_uri: root_url.chomp('/'))

    if !profile['sub']
      redirect_to auth_failure_path
      return
    end

    @authhash = {
      'provider' => 'google_oauth2',
      'uid' => profile['sub'],
      'name' => profile['name'],
      'email' => profile['email'],
      'first_name' => profile['given_name'],
      'last_name' => profile['family_name'],
      'image_url' => profile['picture'],
    }
    session['authhash'] = @authhash
    auth = Service.find_by(provider: 'google_oauth2', uid: @authhash['uid'])
    if auth && auth.update_attributes(@authhash)
      authenticate_and_redirect(auth.user, auth)
    else
      redirect_to new_session_path
    end
  end

  private

  def authenticate_and_redirect(user, service)
    redirect = session['redirect'] || root_path
    reset_session
    session['user_id'] = user.id
    session['service_id'] = service.id
    redirect_to redirect, :notice => t('sessions.create.success', :provider => @authhash['provider'].humanize)
  end
end
