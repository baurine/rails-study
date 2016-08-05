# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

[
  {
    email: 'test00@mail.com',
    name: 'test00',
    activated: DateTime.now,
    admin: false
  },
  {
    email: 'test01@mail.com',
    name: 'test01',
    activated: DateTime.now,
    admin: false
  },
  {
    email: 'test02@mail.com',
    name: 'test02',
    activated: DateTime.now,
    admin: false
  },
  {
    email: 'test03@mail.com',
    name: 'test03',
    activated: DateTime.now,
    admin: false
  },
  {
    email: 'test04@mail.com',
    name: 'test04',
    activated: DateTime.now,
    admin: false
  }
].each do |p|
  u = User.new(p)
  u.password = '123123'
  if u.save
    puts "save succ #{u}"
  else
    puts u.errors.full_messages
  end
end

100.times do |i|
  Micropost.create(user_id: 1, title: "title-#{i}", content: "content-#{i}")
end
