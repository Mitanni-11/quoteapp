class RhetoricsController < ApplicationController
  before_action :find_rhetoric, only: [:show, :destroy, :image, :edit, :update]
  # ログイン済ユーザーのみにアクセスを許可する
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  include RhetoricsHelper

  def index

    if params[:tag_name]
      @rhetorics = @rhetorics.tagged_with("#{params[:tag_name]}").page(params[:page]).per(20)
    end

    respond_to do |format|
      format.js {}
      format.html {}
    end

  end

  def show
    @comment = Comment.new
    @comments = @rhetoric.comments
    @related_rhetorics = @rhetorics.tagged_with("#{@rhetoric.tag_list}").page(params[:page]).per(20) #同じタグが付いているquoteの表示
  end

  def new
    @rhetoric = current_user.rhetorics.build
  end

  def create
    @rhetoric = current_user.rhetorics.build(rhetoric_params)
    # Helperで生成した画像をimageカラムに
    @rhetoric.image = RhetoricsHelper.build(@rhetoric.meigen, @rhetoric.speaker)
    if @rhetoric.save # ここでuploaderが走る
      slack_notif(@rhetoric)
      flash[:success] = "rhetoricが作成されました！"
      redirect_to @rhetoric
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    # Helperで生成した画像をimageカラムに # rhetoric_paramsからmeigenを取り出す
    @rhetoric.image = RhetoricsHelper.build(rhetoric_params[:meigen], rhetoric_params[:speaker])
    if @rhetoric.update(rhetoric_params)
      flash[:success] = "rhetoricが編集されました！"
      redirect_to @rhetoric
    else
      render 'edit'
    end
  end

  def destroy
    @rhetoric.destroy
    redirect_to root_path
  end

  def image
    send_data @rhetoric.image, type: @rhetoric.ctype, disposition: 'inline'
  end

  private


  def rhetoric_params
    params.require(:rhetoric).permit(:description, :meigen, :tag_list, :speaker, :picture )
  end

  def find_rhetoric
    @rhetoric = Rhetoric.find(params[:id])
  end

  def slack_notif(rhetoric)
    if Rails.env.production?
    notifier = Slack::Notifier.new(Rails.application.config.slack_quote_post_ch_url)
    user = User.find_by(id: rhetoric.user_id)
    attachments = {
        author_name: "#{user.username}さんの投稿",
        text: "https://quote-by.me/rhetorics/#{rhetoric.id}",
        color: "good",
        footer: rhetoric.meigen
    }
    notifier.post attachments: [attachments]
    else
      return
    end
   end
end