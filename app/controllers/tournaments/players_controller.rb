class Tournaments::PlayersController < ApplicationController
  before_filter :find_tournament_and_players
  before_filter :require_owner!

  layout 'tournament_title', :only => [:index]

  def index
    @pending_invite_requests = @tournament.invite_requests.where(invite_id: nil)
  end

  def destroy
    @player = @players.find(params[:id])
    PlayerRemover.new(@player).remove
    redirect_to tournament_players_path
  end

  private

  def find_tournament_and_players
    @tournament = Tournament.friendly.find(params[:tournament_id])
    @players = @tournament.players.includes(:user).order('users.name ASC')
  end

  def require_owner!
    unless current_user.id == @tournament.owner_id
      redirect_to tournament_path(@tournament)
    end
  end
end