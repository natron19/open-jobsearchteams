class JobSeekerProfilesController < ApplicationController
  def show
    @profile = current_user.job_seeker_profile
    redirect_to new_profile_path unless @profile
  end

  def new
    redirect_to profile_path if current_user.job_seeker_profile
    @profile = JobSeekerProfile.new
  end

  def create
    @profile = current_user.build_job_seeker_profile(profile_params)
    if @profile.save
      redirect_to dashboard_path, notice: "Profile saved! Now analyze your first job."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @profile = current_user.job_seeker_profile
    render file: Rails.public_path.join("404.html"), status: :not_found unless @profile
  end

  def update
    @profile = current_user.job_seeker_profile
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:job_seeker_profile).permit(:current_role, :target_role, :top_skills, :biggest_challenge)
  end
end
