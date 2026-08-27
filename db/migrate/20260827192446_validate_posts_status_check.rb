class ValidatePostsStatusCheck < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :posts, name: "posts_status_check"
  end
end
