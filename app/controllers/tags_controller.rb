class TagsController < ApplicationController

  def index
    @popular_tags = ActsAsTaggableOn::Tag.most_used(1) #最も使われている上位10個のタグの取得
    @popular_rhetoric = Rhetoric.tagged_with("#{@popular_tags.name}").maximum(:picks_count) #popular_tagがついている投稿の中で最もpickが多いものを取得
  end

end
