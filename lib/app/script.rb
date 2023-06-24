# frozen_string_literal: true
require "active_model"
require "jsonapi/serializer"
require "amazing_print"
require "pry"

class Script
  include ActiveModel::Model

  attr_accessor :name

  validates :name, presence: true

  def hello
    "hello world"
  end
end

class Movie
  attr_accessor :id,
    :name,
    :year,
    :actor_ids,
    :owner_id,
    :movie_type_id
end

class MovieSerializer
  # https://github.com/jsonapi-serializer/jsonapi-serializer#model-definition
  include JSONAPI::Serializer

  set_type :movie # optional
  set_id :owner_id # optional
  attributes :name, :year
  # has_many :actors
  # belongs_to :owner, record_type: :user
  # belongs_to :movie_type
end

class ExampleSerialization
  def self.run
    movies =
      2.times.map do |i|
        m = Movie.new
        m.id = i + 1
        m.name = "test movie #{i}"
        m.actor_ids = [1, 2, 3]
        m.owner_id = 3
        m.movie_type_id = 1
        m
      end

    MovieSerializer.new(movies).serializable_hash
  end
end

ap ExampleSerialization.run
