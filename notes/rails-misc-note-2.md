# Rails Misc Note 2

1. class_name
1. routes 中的 resource 与 resources 的区别

## class_name

在 model 中使用 `has_many`, `has_one`, `belongs_to` 等进行关联时，默认后面的参数和关联表名相同，而表名和 model 的 class 相同。比如：

    class User < ApplicationRecord
      has_many :posts
    end

    class Post < ApplicationRecord
      belongs_to :user
    end

如果你不想用默认的名字，比如我不想用 `post.user` 来获得作者，而是想用更明确的名字，比如 author 或 writer，那么可以这样定义：

    class Post < ApplicationRecord
      belongs_to :author, class_name: 'User'
    end

上面这样的定义，默认 posts 表与 users 表关联的 `foreign_key` 是 `author_id`，如果 `foreign_key` 不是 `author_id`，比如是 `user_id`，那么还需要显示地用 `foreign_key` 参数声明，比如：

    class Post < ApplicationRecord
      belongs_to :author, class_name: 'User', forign_key: 'user_id'
    end

来看一个稍微复杂的例子，[Self Join](http://guides.rubyonrails.org/association_basics.html#self-joins)

    class Employee < ApplicationRecord
      has_many :subordinates, class_name: "Employee",
                              foreign_key: "manager_id"

      belongs_to :manager, class_name: "Employee"
    end

employees 表中有一列 `manager_id` 来关联到 employees 表中的另一个记录。

再看一个更复杂的例子，摘自 *Ruby on Rails Tutorial*

    class CreateRelationships < ActiveRecord::Migration[5.0]
      def change
        create_table :relationships do |t|
          t.integer :follower_id
          t.integer :followed_id

          t.timestamps
        end
        add_index :relationships, :follower_id
        add_index :relationships, :followed_id
        add_index :relationships, [:follower_id, :followed_id], unique: true
      end
    end

    class Relationship < ApplicationRecord
      belongs_to :follower, class_name: "User"
      belongs_to :followed, class_name: "User"
    end

    class User < ApplicationRecord
      # active relation with follower
      has_many :active_relationships, class_name: "Relationship",
                                      foreign_key: "follower_id",
                                      dependent: :destroy
      has_many :following, through: :active_relationships, source: :followed

      # passive relation with follow
      has_many :passive_relationships, class_name: "Relationship",
                                       foreign_key: "followed_id",
                                       dependent: :destroy
      has_many :followers, through: :passive_relationships, source: :follower

      ...
    end

结合上一篇的 `has_many / through / source` 来看，在为关联属性取别名时，source 总是和 through 一起使用，而 `foreign_key` 总是和 `class_name` 一起使用。

## routes 中的 resource 与 resources 的区别

以一个博客网站为例，一个用户可以给一篇文章创建多个评论，即 routes 应该是这样的：

    resources :posts do
      resources :comments
    end

这样，在用户登录的情况下，创建一个新的评论的 API 是 `POST /posts/:post_id/comments`，删除一个 comment 的 API 是 `DELETE /posts/:post_id/comments/:id`，我们也通过下面的路由来快速地删除一个 comment：

    resources :comments, except: :create

这样，删除一个 comment 也可以用 API: `DELETE /comments/:id`。

和 comment 允许多个不一样的是，如果允许用户对一篇文章进行 favorite/like/star，无论操作多少次，都只会生成一个 favorite/like/star。假如我们对一篇文章进行 like，可以用 API `POST /posts/:post_id/likes`，但是删除的时候，我们更希望用 `DELETE /posts/:post_id/likes`，而不是 `DELETE /posts/:post_id/likes/:id` 或 `DELETE /likes/:id`，因为每个用户对一篇文章只有一个 like，那么此时，我们就要在 routes 中使用 resource，而不是 resources 了：

    resources :posts do
      resources :comments
      resource  :likes
    end

`resources :likes` 将会生成 `DELETE /posts/:post_id/likes/:id` 的 API，而 `resource :likes` 生成 `DELETE /posts/:post_id/likes` 的 API。

至于 resource 后面应该用 `like` 还是 `likes`，其实也不好定夺，因为对某篇 post 来说，它是可以有多个 likes 的呀，但对于一个用户来说，它对某篇 post 只能有一个 like，所以我持保留意见，`like` 或 `likes` 都可以。

如果是 `resouce :like`，那么生成的 API 是这样的：`POST /posts/:post_id/like`, `DELETE /posts/:post_id/like`。

阅读了 [GitHub 关于此类 API 的设计](https://developer.github.com/v3/activity/starring/#star-a-repository) 后，我觉得上面这个 API 更好的设计是这样的：

    # 获取自己或某人是否 like 了某篇文章
    GET /user/liked/posts/:post_id
    GET /users/:user_id/liked/posts/:post_id

    # like 一篇文章，操作是幂等的
    PUT /user/liked/posts/:post_id

    # un-like 一篇文章
    DELETE /user/liked/posts/:post_id

相比上面的设计更合理的地方在于，like post 应该是幂等操作，而一般来说 PUT 是幂等的，而 POST 不是。在 API url 中同时体现了主语和宾语，也更合理。

那这样的 API routes 应该怎么写呢？

    resource :user do
      resource :liked, only: [] do
        resources :posts, only: [:index, :show, :update, :destroy], controller: :liked, param: :post_id
      end
    end

得到的路由是这样的：

    user_liked_posts GET    /user/liked/posts(.:format)                         liked#index
     user_liked_post GET    /user/liked/posts/:post_id(.:format)                liked#show
                     PATCH  /user/liked/posts/:post_id(.:format)                liked#update
                     PUT    /user/liked/posts/:post_id(.:format)                liked#update
                     DELETE /user/liked/posts/:post_id(.:format)                liked#destroy

注意，如果你不加上 `controller: :liked, param: :post_id`，那么得到的默认路由是这样的：

    user_liked_posts GET    /user/liked/posts(.:format)                         posts#index
     user_liked_post GET    /user/liked/posts/:id(.:format)                     posts#show
                     PATCH  /user/liked/posts/:id(.:format)                     posts#update
                     PUT    /user/liked/posts/:id(.:format)                     posts#update
                     DELETE /user/liked/posts/:id(.:format)                     posts#destroy
