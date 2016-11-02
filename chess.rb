# Consider having a single class for "piece"
# Consider changing string arguments to symbols
# Consider tyring a different way for dealing with empty squares
# Change limited_scope of board's co-ordinate numbers
# Time, castling, en passant, saving, checkmate, AI

##############################################################################
# NEXT,
#
#
###########################################################################

module HelperMethods

    def unlimited_scope(layout, color, l, l_step, n, n_step)
        moves = []
        while layout[(l + l_step).chr + (n + n_step).chr].class == EmptySquare
            moves << (l + l_step).chr + (n + n_step).chr
            l = l + l_step
            n = n + n_step
        end

        next_square = (l + l_step).chr + (n + n_step).chr
        moves << next_square unless layout[next_square].nil? || layout[next_square].color == color

        moves
    end

    def limited_scope(layout, l_step, n_step)
        square = (@pos[0].ord + l_step).chr + (@pos[1].ord + n_step).chr

        if layout.has_key? square
            square
        else
            "Z"
        end
    end

# rook_scope and bishop_scope are to be 'included' in the Queen class.
    def rook_scope(layout, color)
        moves = []
        moves << unlimited_scope(layout, color, pos[0].ord, 0, pos[1].ord, 1)
        moves << unlimited_scope(layout, color, pos[0].ord, 0, pos[1].ord, -1)
        moves << unlimited_scope(layout, color, pos[0].ord, 1, pos[1].ord, 0)
        moves << unlimited_scope(layout, color, pos[0].ord, -1, pos[1].ord, 0)
        moves.flatten
    end

    def bishop_scope(layout, color)
        moves = []
        moves << unlimited_scope(layout, color, pos[0].ord, -1, pos[1].ord, -1)
        moves << unlimited_scope(layout, color, pos[0].ord, 1, pos[1].ord, -1)
        moves << unlimited_scope(layout, color, pos[0].ord, 1, pos[1].ord, 1)
        moves << unlimited_scope(layout, color, pos[0].ord, -1, pos[1].ord, +1)
        moves.flatten
    end

end

class OffBoard
    attr_accessor :color, :form
    def initialize()
        @color = nil
        @form = nil
    end
end

class EmptySquare
    attr_accessor :form, :color, :pos

    def initialize(pos)
        @color = nil
        @pos = pos
        @form = "."
    end
end

class Pawn
    include HelperMethods
    attr_accessor :color, :symbol, :form, :pos, :scope, :value, :moved

    def initialize(color, pos)
        @color = color
        @symbol = nil
        @form = color == "black" ? "♙" : "♟"
        @pos = pos
        @value = 1
        @moved = false
    end

    def scope(layout)
        moves = []

        n = limited_scope(layout, 0, -1);   nn = limited_scope(layout, 0, -2)
        nw = limited_scope(layout, -1, -1); ne = limited_scope(layout, 1, -1)
        s = limited_scope(layout, 0, 1);    ss = limited_scope(layout, 0, 2)
        sw = limited_scope(layout, -1, 1);  se = limited_scope(layout, 1, 1)

        if @color == "white"
            if layout[n].class == EmptySquare
                moves << n
                moves << nn if @pos[1] == "7" && layout[nn].class == EmptySquare
            end
            moves << nw if layout[nw].color == "black"
            moves << ne if layout[ne].color == "black"
        elsif @color == "black"
            if layout[s].class == EmptySquare
                moves << s
                moves << ss if @pos[1] == "2" && layout[ss].class == EmptySquare
            end
            moves << sw if layout[sw].color == "white"
            moves << se if layout[se].color == "white"
        end

        moves
    end
end

class Rook
    include HelperMethods
    attr_accessor :color, :symbol, :form, :pos, :scope, :value, :moved, :side

    def initialize(color, pos, side = "kingside")
        @color = color
        @pos = pos
        @side = side
        @symbol = "R"
        @form = color == "black" ? "♖" : "♜"
        @value = 5
        @moved = false
    end

    def scope(layout)
        rook_scope(layout, @color)
    end
end

class Bishop
    include HelperMethods
    attr_accessor :color, :symbol, :form, :pos, :scope, :value, :moved

    def initialize(color, pos)
        @color = color
        @pos = pos
        @symbol = "B"
        @form = color == "black" ? '♗' : '♝'
        @value = 3
        @moved = false
    end

    def scope(layout)
        bishop_scope(layout, @color)
    end
end

class Queen
    include HelperMethods
    attr_accessor :color, :symbol, :form, :pos, :scope, :value, :moved, :side

    def initialize(color, pos, side = "queenside")
        @color = color
        @pos = pos
        @side = side
        @symbol = "Q"
        @form = color == "black" ? '♕' : '♛'
        @rook = Rook.new(color, pos, side)
        @bishop = Bishop.new(color, pos)
        @value = 9
        @moved = false
    end

    def scope(layout)
        @rook.pos = @pos
        @bishop.pos = @pos
        moves = []
        moves << @rook.scope(layout) << @bishop.scope(layout)
        moves.flatten
    end
end

class King
    include HelperMethods
    attr_accessor :color, :symbol, :form, :pos, :scope, :value, :moved, :side

    def initialize(color, pos, side = "kingside")
        @color = color
        @pos = pos
        @side = side
        @symbol = "K"
        @form = color == "black" ? '♔' : '♚'
        @value = 100
        @moved = false
    end

    def scope(layout)
        moves = []
        steps = [-1, 0, 1]
        steps.each do |s1|
            steps.each do |s2|
                unless (layout[limited_scope(layout, s1, s2)].color == @color)
                    moves << limited_scope(layout, s1, s2)
                end
            end
        end

        moves.reject {|e| e == "Z"}
    end
end

class Knight
    include HelperMethods
    attr_accessor :color, :symbol, :form, :pos, :scope, :value, :moved

    def initialize(color, pos)
        @color = color
        @symbol = "N"
        @form = color == "black" ? '♘' : '♞'
        @pos = pos
        @value = 3
        @moved = false
    end

    def scope(layout)
        moves = []
        steps = [-2, -1, 1, 2]
        steps.each do |s1|
            steps.each do |s2|
                unless (layout[limited_scope(layout, s1, s2)].color == @color) || s1.abs == s2.abs
                    moves << limited_scope(layout, s1, s2)
                end
            end
        end

        moves.reject {|e| e == "Z"}
    end
end

class HumanPlayer
    attr_accessor :color

    def initialize(color)
        @color = color
    end

    def input
        puts "#{$b.status["playing"].capitalize} to move"
        move = gets.chomp
        puts ""
        standard_move = move.upcase.scan(/[A-H][1-8]/)
        castle = move.upcase.scan(/[0O]/)

        if standard_move.size > 1
            origin = standard_move[0][-2..-1]
            target = standard_move[1][-2..-1]

            $b.move(origin, target)
        elsif castle.size.between?(2, 3)
            $b.can_castle?(castle)
        else
            puts "- Sorry, unrecognized instruction, please try again."
            input
        end
    end
end

class ComputerPlayer
    attr_accessor :color

    def initialize(color)
        @color = color
    end

    def input
        pieces = $b.all_of($b.status["playing"])
        piece = pieces[rand(pieces.size)]

        origin = piece.pos
        scope = piece.scope($b.layout)
        target = scope[rand(scope.size)]

        $b.move(origin, target)
    end
=begin
    def pieces_exposed
        exposed = []
        $b.all_of($b.status.["playing"]).each do |piece|
            exposed << if total_scope($b.status["waiting"]).include? piece
        end
    end

    def protected?(color)

    end

    def stage

    end
=end
end

class Board
    attr_accessor :play, :layout, :captured, :color, :player

    def initialize
        @play = 1
        @layout = Hash.new
        @black_king = King.new("black", "D1", "kingside")
        @white_king = King.new("white", "D8", "kingside")

        @layout["A1"] = Rook.new("black", "A1", "kingside")
        @layout["H1"] = Rook.new("black", "H1", "queenside")
        @layout["B1"] = Knight.new("black", "B1")
        @layout["G1"] = Knight.new("black", "G1")
        @layout["C1"] = Bishop.new("black", "C1")
        @layout["F1"] = Bishop.new("black", "F1")
        @layout["D1"] = @black_king
        @layout["E1"] = Queen.new("black", "E1", "queenside")
        ("A".."H").to_a.each { |l| @layout[l + 2.to_s] = Pawn.new("black", l + 2.to_s)}

        @layout["A8"] = Rook.new("white", "A8", "kingside")
        @layout["H8"] = Rook.new("white", "H8", "queenside")
        @layout["B8"] = Knight.new("white", "B8")
        @layout["G8"] = Knight.new("white", "G8")
        @layout["C8"] = Bishop.new("white", "C8")
        @layout["F8"] = Bishop.new("white", "F8")
        @layout["D8"] = @white_king
        @layout["E8"] = Queen.new("white", "E8", "queenside")
        ("A".."H").to_a.each { |l| @layout[l + 7.to_s] = Pawn.new("white", l + 7.to_s)}

        @layout["Z"] = OffBoard.new

        @player = {}
        @color = ["black", "white"]
        @captured = {"black" => [], "white" => []}

    end

    def status
        status = {
            "playing" => @color[@play % 2],
            "waiting" => @color[(@play + 1) % 2]
        }
    end

    ####################################################################################
    # DISPLAY
    ####################################################################################
    def print_board
        numbers = ("1".."8").to_a
        letters = ("A".."H").to_a

        puts "\n    A B C D E F G H"

        numbers.each do |n|
            print "#{n}   "
            letters.each do |l|
                square = l + n
                $b.layout[square] ||= EmptySquare.new(square)
                print "#{$b.layout[square].form} "

            end
            print "  #{n}\n"
        end

        puts "    A B C D E F G H\n\n"
    end

    def captured_display(color)
        line = ""
        sorted = ($b.captured[color].sort_by {|piece| piece.value}).reverse
        sorted.each {|piece| line <<"#{ piece.form} "}
        line.center(24)
    end

    def display
        puts "" unless captured_display("white").strip.empty?
        puts captured_display("white")
        print_board
        puts captured_display("black")
        puts "" unless captured_display("black").strip.empty?
    end

    def print_move(origin, target)
        color = $b.status["playing"].capitalize
        symbol = $b.layout[target].symbol
        piece = $b.layout[target].class

        puts "#{color}: #{symbol}#{origin.downcase}:#{target.downcase}"
    end

    ####################################################################################
    # CHECK (MATE)
    ####################################################################################
    def all_of(color)
        pieces = []
        $b.layout.each_value { |piece| pieces << piece if piece.color == color }
        pieces
    end

    def total_scope(color)
        scope = {}
        $b.layout.each_value {|piece| scope[piece] = piece.scope($b.layout) if piece.color == color}
        scope
    end

    def find(type)
        found = {}
        $b.layout.each_value do |piece|
            found[[piece.color, piece.side]] = piece if piece.class == type
        end
        found
    end

    def king(role)
        find(King)[[$b.status[role], "kingside"]]
    end

    def check?(piece)
        threat_col = ($b.color - [piece.color]).first
        threats = []
        total_scope(threat_col).each do |threat, scope|
            threats << threat.pos if scope.include? piece.pos
        end

        threats
    end

    def check_own(origin, target, piece_taken)

        if !check?(king("playing")).empty?
            puts "\n - ILLEGAL MOVE. King exposed to check.\n\n"
            $b.layout[origin] = $b.layout[target]
            $b.layout[origin].pos = origin
            $b.layout[target] = piece_taken ? $b.captured[$b.status["waiting"]].pop : EmptySquare.new(target)
            @player[status["playing"]].input
        else
            print_move(origin, target)
        end
    end

    def cm_can_move?
        escape = false
        king_scope = king("waiting").scope($b.layout)

        king_scope.each do |square|
            original = $b.layout[square]
            $b.layout[square] = King.new($b.status["waiting"], square)
            escape = true if check?($b.layout[square]).empty?
            $b.layout[square] = original
        end
        escape
    end

    def cm_can_neutralize_threat?
        threat = check?(king("waiting"))
        first_threat = $b.layout[threat.first]
        $b.layout[threat.first] = EmptySquare.new(first_threat) # expands the scope of same color pieces to protect this piece

        defence = []
        total_scope($b.status["waiting"]).each do |piece, scope|
            defence << piece if (scope.include? threat.first ) && (piece.class != King)
        end

        support = []
        total_scope($b.status["playing"]).each do |piece, scope|
            support << piece if scope.include? threat.first
        end

        $b.layout[threat.first] = first_threat # replaces previously removed piece to the board

        if threat.size > 1
            false
        elsif defence.empty?
            false
        elsif (defence.size == 1) && (defence.first.class == King) && (!support.empty?)
            false
        else
            true
        end
    end

    def bounded_squares(other, role)
        k = find(King)[[$b.status[role], "kingside"]].pos
        oth = other.dup
        steps = []

        10.times do
        #until (threat[0] == k[0]) && (threat[0] == k[1])
            steps << "#{oth[0]}#{oth[1]}"
            oth[0] = (oth[0].ord + (k[0] <=> oth[0])).chr
            oth[1] = (oth[1].ord + (k[1] <=> oth[1])).chr
        end
        steps - [steps[0]] - [steps[-1]]
    end

    def cm_can_block?(threat)
        scope_arr = []
        total_scope($b.status["waiting"]).each_value do |scope|
            scope_arr << scope
        end

        (scope_arr & bounded_squares(threat, "waiting")).empty? ? false : true
    end

    def checkmate()
        threat = check?(king("waiting")).first

        #puts "cm_can_move: #{cm_can_move?}"
        #puts "cm_can_neutralize_threat: #{cm_can_neutralize_threat?}"
        #puts "cm_can_block: #{cm_can_block?(threat)}"

        if !cm_can_move? && !cm_can_neutralize_threat? && !cm_can_block?(threat)
            puts " - CHECKMATE!"
            puts " - #{($b.status["playing"]).capitalize} wins.\n\n"
            exit(0)
        else
            puts " - CHECK\n\n"
        end
    end

    def check_other
        if !check?(king("waiting")).empty?
            checkmate
        end
    end

    ####################################################################################
    # MOVE
    ####################################################################################

    def remove(piece)
        $b.captured[piece.color] << piece
    end

    def move(origin, target)
        piece = $b.layout[origin]
        target_piece = $b.layout[target]

        playing_pieces = $b.layout.select {|square| $b.layout[square].color == $b.status["playing"]}
        piece_taken = false

        if (playing_pieces.has_value? piece) && (piece.scope($b.layout).include? target)
            if target_piece.class != EmptySquare
                remove(target_piece)
                piece_taken = true
            end
            $b.layout[target] = piece
            piece.pos = target
            $b.layout[origin] = EmptySquare.new(origin)

            piece.moved = true if piece.class == Rook || piece.class == King
            pawn_promotion(piece) if piece.class == Pawn && !target[1].to_i.between?(2, 7)

            check_own(origin, target, piece_taken)
        else
            puts "\n - ILLEGAL MOVE. Try again.\n\n" unless $b.player[$b.status["playing"]].class == ComputerPlayer
            #puts $b.player[$b.status["playing"]].class
            #puts "#{piece}: #{piece.scope($b.layout)}"
            #puts "#{origin}, #{target}"
            @player[status["playing"]].input
        end

    end

    ####################################################################################
    # CASTLING
    ####################################################################################
    def rook(input)
        direction = input.size == 2 ? "kingside" : "queenside"
        find(Rook)[[$b.status["playing"], direction]]
    end

    def moved?(input)
        rook_moved = rook(input).moved
        king_moved = king("playing").moved
        puts "rook_moved: #{rook_moved}"
        puts "king_moved: #{king_moved}"
        rook_moved || king_moved ? true : false
    end

    def in_check?(input)
        rook_id = rook(input)
        king_id = king("playing")
        key_squares = bounded_squares(rook(input).pos, "playing") << rook_id.pos << king_id.pos

        in_check = false
        key_squares.each do |square|
            original = $b.layout[square]
            $b.layout[square] = king_id
            in_check = true if !check?($b.layout[square]).empty?
            $b.layout[square] = original
         end
        in_check
    end

    def blocked?(input)
        key_squares = bounded_squares(rook(input).pos, "playing")
        blocked = false

        key_squares.each do |square|
            blocked = true if $b.layout[square].class != EmptySquare
        end
        blocked
    end

    def castling(inp)
        king_xy = king("playing").pos
        rook_xy = rook(inp).pos

        direction = (rook_xy[0] <=> king_xy[0])
        new_king_xy = (king_xy[0].ord + 2 * direction).chr + king_xy[1]
        new_rook_xy = (new_king_xy[0].ord - direction).chr + rook_xy[1]

        $b.layout[new_king_xy] = $b.layout[king_xy]
        $b.layout[new_rook_xy] = $b.layout[rook_xy]
        $b.layout[rook_xy] = EmptySquare.new(rook_xy)
        $b.layout[king_xy] = EmptySquare.new(king_xy)

        $b.layout[new_king_xy].moved = true
        $b.layout[new_rook_xy].moved = true
    end

    def can_castle?(inp)
        input = @player[status["playing"]].input

        if moved?(inp)
            puts "- One of your key pieces has moved.\n\n"; input
        elsif blocked?(inp)
            puts "- Your path is not clear to castle.\n\n"; input
        elsif in_check?(inp)
            puts "-One of your key pieces or squares in between is in check.\n\n"; input
        else
            castling(inp)
        end
    end

    ####################################################################################
    # PAWN PROMOTION
    ####################################################################################
    def pawn_promotion(piece)
        puts "- Which piece would you like to promote your pawn to?"
        selection = gets.chomp.downcase
        puts ""

        col = piece.color
        pos = piece.pos

        case selection
        when "rook" then $b.layout[piece.pos] = Rook.new(col, pos)
        when "knight" then $b.layout[piece.pos] = Knight.new(col, pos)
        when "bishop" then $b.layout[piece.pos] = Bishop.new(col, pos)
        when "queen" then $b.layout[piece.pos] = Queen.new(col, pos)
        when "king", "pawn"
            puts "- A pawn may not be promoted to a #{selection}."
            pawn_promotion(piece)
        else
            puts "- Input not recognized. Please try again."
            pawn_promotion(piece)
        end
    end

    def players(color)
        puts "\nWho will play as #{color}?"
        puts "1. Human"
        puts "2. Computer"
        selection = gets.chomp

        @player[color] =
            case selection
            when /1/ then HumanPlayer.new(color)
            when /2/ then ComputerPlayer.new(color)
            else
                "Unrecognized selection. Please try again."
                players(color)
            end
        @player
    end

    def turn

    end
end

####################################################################################
# MAIN LOOP
####################################################################################
$b = Board.new
$b.players("white")
$b.players("black")

$b.display
loop do
    $b.player[$b.status["playing"]].input

    $b.display
    $b.check_other
    $b.play += 1
end
