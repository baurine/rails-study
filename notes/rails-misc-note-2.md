# Rails Misc Note 2

1. has_many / through / source / source_type / as / alias_attribute / class_name

## has_many / through / source / source_type / as / alias_attribute / class_name

Ref: [Understanding :source option of has_one/has_many through of Rails](https://stackoverflow.com/questions/4632408/understanding-source-option-of-has-one-has-many-through-of-rails)

假设我们有一个 users 表，一个 posts 表，每个用户可以发表多个 post，也可以 like 别人或自己的 post，因此我们需要一个 likes 的关联表。它们的定义如下：

    class User < ApplicationRecord
      has_many :posts

      has_many :likes
    end

    class Like < ApplicationRecord
      belongs_to :user
      belongs_to :post
    end

    class Post < ApplicationRecord
      belongs_to :user
      has_many :likes
    end

假如我们想得到 like 了某篇 post 的 users，那么我们要给 Post 增加一个 users 的属性，这个 users 属性必须通过关联表 likes 来得到，因此可以这样定义：

    class Post < ApplicationRecord
      belongs_to :user

      has_many :likes
      has_many :users, through: :likes
    end

当我们使用 `has_many :users, throught: :likes` 的语法时，rails 会自动去 likes 关联表找对应的 users。

通过上面的操作，我们可以用 `post.user` 得到 post 的作者，用 `post.users` 得到 post 被哪些用户所 like 了。

但 `post.users` 很明显意义不够明确，如果能用 `post.liked_users` 来得到那些 like 了此 post 的用户，那就更好。

因此我们尝试用 `has_many :liked_users, through: :likes` 来定义，但运行出错，rails 并没有那么智能，它并不知道通过 likes 关联表如何得到 `liked_users`，因此我们要显式地告诉它，实际是要去找 users。因此，这就是 source 参数的作用：

    has_many :liked_users, through: :likes, source: :users

也可以通过 alias_attribute 来实现 (已验证可行)

    class Post < ApplicationRecord
      belongs_to :user

      has_many :likes
      has_many :users, through: :likes
      alias_attribute :liked_users, :users
    end

但也不是所有情况都可以用 alias。我们来看如何得到 user 所 like 的所有 post，本来我们可以很简单地使用 `has_many :posts, through: :likes` 来得到，但首先，user 已经有同名的 posts 属性了，名字产生了冲突 (因此这种情况下 alias 就没法工作了)，其次，单纯的 `user.posts` 意义也不明确，人们更容易理解它为这个用户发表的 posts，而不是 like 的 posts，所以我们用下面的语句来解决上面两个问题：

    class User < ApplicationRecord
      has_many :posts

      has_many :likes
      has_many :liked_posts, through: :likes, source: :posts
    end

如果关联表关联的是多态对象，那么在 source 后面，还有一个 `source_type` 的参数，它必须和 `as` 参数配套使用。

看这里的解释：[Need help to understand :source_type option of has_one/has_many through of Rails](https://stackoverflow.com/questions/9500922/need-help-to-understand-source-type-option-of-has-one-has-many-through-of-rails).

示例代码：

    class Tag < ActiveRecord::Base
      has_many :taggings, :dependent => :destroy
      has_many :books,  :through => :taggings, :source => :taggable, :source_type => "Book"
      has_many :movies, :through => :taggings, :source => :taggable, :source_type => "Movie"
    end

    # 关联表，多态表，实现会生成三列：tag_id, taggable_id, taggable_type
    class Tagging < ActiveRecord::Base
      belongs_to :tag
      belongs_to :taggable, :polymorphic => true
    end

    class Book < ActiveRecord::Base
      has_many :taggings, :as => :taggable
      has_many :tags, :through => :taggings
    end

    class Movie < ActiveRecord::Base
      has_many :taggings, :as => :taggable
      has_many :tags, :through => :taggings
    end

如果以上面的 Like 为例，假设 user 即可以 like 一篇 post，也可以 like 一个 comment，那么 model 关系是这样的：

    class User < ApplicationRecord
      has_many :posts, dependent: :destroy
      has_many :comments, dependent: :destroy

      has_many :likes, dependent: :destroy
      has_many :liked_posts,    through: :likes,    source: :likeable, source_type: 'Post'
      has_many :liked_comments, through: :comments, source: :likeable, source_type: 'Comment'
    end

    # 关联表，多态表，生成三列：user_id, likeable_id, likeable_type
    class Like < ApplicationRecord
      belongs_to :user

      belongs_to :likeable, polymorphic: true
    end

    class Post < ApplicationRecord
      belongs_to :user

      has_many :likes, as: :likeable
      # has_many :users, through: :likes
      # alias_attribute :liked_users, :users
      has_many :liked_user, through: :likes, source: :users
    end

    class Comment < ApplicationRecord
      belongs_to :user

      has_many :likes, as: :likeable
      # has_many :users, through: :likes
      # alias_attribute :liked_users, :users
      has_many :liked_user, through: :likes, source: :users
    end

**class_name**

在上面的例子中，我们是给通过多对多的关联表关联的属性取了别名，那如果想给通过一对一或一对多进行关联的属性取别名呢，这时候就需要使用 `class_name` 了，上面说的 `alias_attribute` 也适用这种情况。

Ref: [Rails has_many with alias name](https://stackoverflow.com/questions/1163032/rails-has-many-with-alias-name)

在 model 中使用 `has_many`, `has_one`, `belongs_to` 等进行一对一或一对多关联时，默认后面的参数和关联表名相同，而表名和 model 的 class 相同。比如：

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

总结：在为一对一或一对多的关联属性取别名时，可以用 `class_name` 和 `foreign_key`，在为多对多的关联属性取别名时，可以用 `through / source / source_type`，而 `alias_attribute` 在某些情况下可以适用于两者，但还是推荐前面的两种方法。
