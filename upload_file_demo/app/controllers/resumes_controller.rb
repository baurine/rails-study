class ResumesController < ApplicationController
  def index
    @resumes = Resume.all
  end

  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new(resume_params)
    if @resume.save
      redirect_to resumes_path, notice: "The resume #{@resume.name} has been uploaded."
    else
      render 'new'
    end
  end

  def destroy
    @resume = Resume.find(params[:id])
    @resume.destroy
    redirect_to resumes_path, notice: "The resume #{@resume.name} has been deleted."
  end

  def upload
    uploaded_file = params[:image_file]
    original_filename = uploaded_file.original_filename.downcase
    puts uploaded_file
    puts original_filename

    if /\.(jpeg|jpg|png)$/.match(original_filename)
      resume = Resume.new(name: original_filename)
      resume.attachment = uploaded_file
      resume.save!
      render json: { url: resume.attachment.url }, status: 200
    else
      render json: { msg: 'File is invalid!' }, status: 200
    end
  end

  private
  def resume_params
    params.require(:resume).permit(:name, :attachment)
  end
end
