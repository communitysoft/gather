# frozen_string_literal: true

class FixWikiIndices < ActiveRecord::Migration[4.2]
  def change
    add_index :wiki_pages, :updator_id
    remove_index :wiki_pages, :slug
    add_index :wiki_pages, %i[community_id slug], unique: true
    add_index :wiki_pages, %i[community_id title], unique: true
  end
end
