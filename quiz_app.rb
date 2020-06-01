require 'sinatra/base'
require './models/quiz'
require './models/player'
require './models/request'
require './models/question'

class Game
  attr_accessor :quiz, :player

  def initialize
    @quiz = Quiz.new
    @player = Player.new
  end

  def new_quiz
    @quiz = Quiz.new
  end

end

class QuizApp < Sinatra::Base
  URL_GET_QUESTIONS = 'https://zbpbzqjeje.execute-api.us-east-1.amazonaws.com/default/get_questions'
  URL_SCORES = 'https://ezq2yyaea4.execute-api.us-east-1.amazonaws.com/default/scores'

  game = Game.new

  get '/' do
    @title_page = 'Pine app'
    erb :welcome, layout: :template
  end

  get '/start-quiz' do
    @title_page = 'Quiz'
    erb :start, layout: :template
  end

  post '/scores' do
    @title_page = 'Scores'
    game.player.score = params['grade'].to_i

    @username = game.player.username
    @score = game.player.score

    response = Request.post_request(URL_SCORES, {
        username: game.player.username,
        score: game.player.score
    })

    @scores = Request.manage_response(response)

    erb :scores, layout: :template
  end

  post '/quiz' do
    game.new_quiz
    @title_page = 'Quiz app'

    number_questions = params['question_number'].to_i
    game.player.username = params['username']

    if number_questions < 1 or number_questions > 10
      redirect '/start-quiz'
    else
      response = Request.post_request(URL_GET_QUESTIONS, {
          number: number_questions
      })

      questions_response = Request.manage_response(response)

      questions_response.each do |question|
        game.quiz.question_answer << question['Answer']
        game.quiz.questions << Question.new(question)
      end

      @questions = game.quiz.questions

      erb :quiz, layout: :template
    end
  end

  post '/get-feedback' do
    @title_page = 'Feedback'

    answers = []
    params.each { |question, answer| game.quiz.user_answer << answer.to_i }

    game.player.score = (game.quiz.number_corrects * 100) / game.quiz.question_answer.length
    @feedback = game.player.score

    @questions = game.quiz.questions
    @user_answer = game.quiz.user_answer

    erb :feedback, layout: :template
  end
end

