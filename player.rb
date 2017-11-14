class Player

  DIRECTIONS = [:forward, :backward]

  def each_direction(&block)
    DIRECTIONS.each do |direction|
      yield(direction)
    end
    nil
  end

  def initialize()
    @health = 20
  end

  def play_turn(warrior)
    @warrior = warrior
    rescue_captive || shoot || handle_low_health || walk

    @health = warrior.health
  end

  def under_attack?
    @health > @warrior.health
  end

  def walk
    if @warrior.feel.wall?
      @warrior.pivot!
      return true
    else
      @warrior.walk!
      return true
    end
  end

  # Rest on low_health when no under attack
  def handle_low_health
    if @warrior.health < 20
      if !under_attack?
        @warrior.rest!
        return true
      end
    end
  end

  # Try to resuce captives
  def rescue_captive
    each_direction do |dir|
      #Rescue near captive
      if @warrior.feel(dir).captive?
        @warrior.rescue!(dir)
        return true
      end

      #See if there are any captive to rescue nearby
      spaces = @warrior.look(dir)
      space = spaces.find{ |space| space.captive? }
      if space
        @warrior.walk!(dir)
        return true
      end
    end
  end

  # Shoot enemys nearby
  def shoot
    #First check if there is an archer enemy in any direction and attack if so
    return true if shoot_archer

    each_direction do |dir|
      enemy_to_shoot = enemy_to_shoot?(dir)
      if enemy_to_shoot
        @warrior.shoot!(dir)
        return true
      end
    end
  end

  # Shoot the archer if there is one in any position
  def shoot_archer
    dir = archer_direction
    if dir
      @warrior.shoot!(dir)
      return true
    end
  end

  # Return the dir of the archer if there is one
  def archer_direction
    DIRECTIONS.find do |dir|
      enemy_to_shoot?(dir, "a")
    end
  end

  # Check if there is an enemy to shoot in the direction
  # if character is present it checks for that type of enemy
  def enemy_to_shoot?(dir, character = nil)
    spaces = @warrior.look(dir)
    space = spaces.find{ |space| space.enemy? }
    if space
      not_captives = spaces[0..space.location.first - 1].all? { |space| !space.captive? }
      not_captives &= space.unit.character == character if character
      return not_captives
    end
  end
end
