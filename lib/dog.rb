require 'pry'
class Dog
  attr_accessor :name, :breed
  attr_reader :id

  def initialize(id: nil, name:, breed:)
    @id = id
    @name = name
    @breed = breed
  end

  def self.create_table
    sql = <<-sql
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    sql

    DB[:conn].execute(sql)
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE dogs")
  end

  def save
    if !!self.id == true
      sql = <<-sql
        UPDATE dogs
        SET (name, breed)
        VALUES (?, ?)
      sql

      DB[:conn].execute(sql, self.name, self.breed)
      self
    else
      sql = <<-sql
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      sql

      DB[:conn].execute(sql, self.name, self.breed)

      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
    end
  end

  def self.create(hash)
    new_dog = Dog.new(name: hash[:name], breed: hash[:breed])
    new_dog.save
  end

  def self.find_by_id(id)
    sql = <<-sql
      SELECT *
      FROM dogs
      WHERE id = ?
      LIMIT 1
    sql

    row = DB[:conn].execute(sql, id)[0]
    Dog.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.find_or_create_by(hash)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", hash[:name], hash[:breed])
    if !dog.empty?
      dog_data = dog[0]
      dog = Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
    else
      dog = self.create(name: hash[:name], breed: hash[:breed])
    end
    dog
  end

  def self.new_from_db(row)
    Dog.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.find_by_name(name)
    sql = <<-sql
      SELECT *
      FROM dogs
      WHERE name = ?
      LIMIT 1
    sql

    row = DB[:conn].execute(sql, name)[0]
    self.new_from_db(row)
  end

  def update
    sql = <<-sql
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?
    sql

    row = DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

end
