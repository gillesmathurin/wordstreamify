ActiveRecord::Schema.define(:version => 0) do
  create_table :keywords, :force => true do |t|
    t.boolean   :suggestion, :most_common
    t.string    :keyword
  end
end