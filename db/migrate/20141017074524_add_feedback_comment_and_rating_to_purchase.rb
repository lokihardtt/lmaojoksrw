class AddFeedbackCommentAndRatingToPurchase < ActiveRecord::Migration
  def change
    add_column :purchases, :feedback_comment, :string
    add_column :purchases, :rating, :integer, default: 0
  end
end
