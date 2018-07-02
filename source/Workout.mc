using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.System;
using Toybox.WatchUi as Ui;

class WorkoutDelegate extends Ui.BehaviorDelegate {

  private var mModel;

  function initialize() {
    BehaviorDelegate.initialize();
    mModel = Application.getApp().model;
  }

  function onMenu() {
    showMenu();
  }

  function onSelect() {
    showMenu();
  }

  function showMenu() {
    var menu = new WatchUi.Menu();
    if(mModel.hasWorkout()) {
      menu.setTitle(mModel.workoutSummary["name"]);
    }
    var stepTarget = mModel.mergedStepTarget();
    var adjustTemperature = mModel.mergedAdjustTemperature();
    var adjustUndulation = mModel.mergedAdjustUndulation();
    var includeRunBackStep = mModel.mergedIncludeRunBackStep();

    switch (mModel.downloadStatus) {
      case DownloadStatus.OK:
        menu.addItem(Ui.loadResource(Rez.Strings.menuStartWorkout), :startWorkout);
        menu.addItem(Ui.loadResource(Rez.Strings.stepTarget) + ": " + stepTarget, :adjustStepTarget);
        menu.addItem(Ui.loadResource(Rez.Strings.menuIncludeRunBackStep) + ": " + yesNo(includeRunBackStep), :adjustIncludeRunBackStep);
        break;
      case DownloadStatus.DEVICE_DOES_NOT_SUPPORT_DOWNLOAD:
        menu.addItem(Ui.loadResource(Rez.Strings.menuDownloadNotSupported), :noWorkoutDownloadNotSupported);
        break;
      case DownloadStatus.NO_WORKOUT:
        menu.addItem(Ui.loadResource(Rez.Strings.menuNoWorkout), :noWorkout);
        break;
      case DownloadStatus.EXTERNAL_SCHEDULE:
      case DownloadStatus.NO_WORKOUT_AVAILABLE:
        menu.addItem(Ui.loadResource(Rez.Strings.menuOpenCommitments), :openCommitments);
        break;
      case DownloadStatus.INSUFFICIENT_SUBSCRIPTION_CAPABILITIES:
        menu.addItem(Ui.loadResource(Rez.Strings.menuNoStartWorkout), :noWorkoutInsufficientSubscriptionCapabilities);
        break;
      case DownloadStatus.WORKOUT_NOT_DOWNLOAD_CAPABLE:
        menu.addItem(Ui.loadResource(Rez.Strings.menuNoStartWorkout), :noWorkoutNotDownloadCapable);
        break;
      case DownloadStatus.NO_FIT_DATADOWNLOAD_RESULT_NO_FIT_DATA_RETURNED:
        menu.addItem(Ui.loadResource(Rez.Strings.menuNoFitDataLoaded), :noFitDataLoaded);
        break;
    }

    if (mModel.isAdjustPermitted()) {
      menu.addItem(Ui.loadResource(Rez.Strings.adjustTemperature) + ": " + yesNo(adjustTemperature), :adjustTemperature);
      menu.addItem(Ui.loadResource(Rez.Strings.adjustUndulation) + ": " + yesNo(adjustUndulation), :adjustUndulation);
    }

    menu.addItem(Ui.loadResource(Rez.Strings.menuRefetchWorkout), :refetchWorkout);

    mModel.addStandardMenuOptions(menu);
    Ui.pushView(menu, new WorkoutMenuDelegate(), Ui.SLIDE_UP);
  }

  function yesNo(val) {
    return Ui.loadResource(val ? Rez.Strings.yes : Rez.Strings.no);
  }

}

class WorkoutMenuDelegate extends Ui.MenuInputDelegate {

  private var mModel;

  function initialize() {
    MenuInputDelegate.initialize();
    mModel = Application.getApp().model;
  }

  function onMenuItem(item) {
    switch(item) {
      case :about:
        Error.showAbout();
        break;
      case :startWorkout:
        System.exitTo(mModel.downloadIntent); // If we popView() before this it breaks on devices but not the simulator
        break;
      default:
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        break;
    }

    switch (item) {
      case :refetchWorkout:
        Ui.switchToView(new DownloadView(), new DownloadDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :switchServer:
        mModel.switchServer();
        Ui.switchToView(new DownloadView(), new DownloadDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :adjustStepTarget:
        var stepTarget = mModel.mergedStepTarget();
        if (stepTarget.equals("SPEED")) {
          stepTarget = "HEART_RATE_RECOVERY";
        } else if (stepTarget.equals("HEART_RATE_RECOVERY")) {
          stepTarget = "HEART_RATE_SLOW";
        } else if (stepTarget.equals("HEART_RATE_SLOW")) {
          stepTarget = "HEART_RATE";
        } else if (stepTarget.equals("HEART_RATE")) {
          stepTarget = "SPEED";
        }
        if (mModel.getDisplayPreferencesStepTarget().equals(stepTarget)) {
          stepTarget = null; // Reset to null if it matches current server choice
        }
        mModel.setStepTarget(stepTarget);
        Ui.switchToView(new DownloadView(), new DownloadDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :adjustIncludeRunBackStep:
        mModel.setIncludeRunBackStep(!mModel.mergedIncludeRunBackStep());
        Ui.switchToView(new DownloadView(), new DownloadDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :adjustTemperature:
        mModel.setAdjustTemperature(!mModel.mergedAdjustTemperature());
        Ui.switchToView(new DownloadView(), new DownloadDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :adjustUndulation:
        mModel.setAdjustUndulation(!mModel.mergedAdjustUndulation());
        Ui.switchToView(new DownloadView(), new DownloadDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :openWebsite:
        Comm.openWebPage(mModel.serverUrl, null, null);
        break;
      case :openCommitments:
        Comm.openWebPage(mModel.serverUrl + "/commitments", null, null);
        break;
      case :switchUser:
        Ui.switchToView(new GrantView(false, true), new GrantDelegate(), Ui.SLIDE_IMMEDIATE);
        break;
      case :noWorkoutDownloadNotSupported:
        Error.showErrorResource(Rez.Strings.errorDownloadNotSupported);
        break;
      case :noWorkoutNotDownloadCapable:
        Error.showErrorResource(Rez.Strings.errorNotDownloadCapable);
        break;
      case :noWorkoutInsufficientSubscriptionCapabilities:
        Error.showErrorResource(Rez.Strings.errorInsufficientSubscriptionCapabilities);
        break;
      case :noWorkout:
        Error.showErrorResource(Rez.Strings.errorNoWorkoutSteps);
        break;
      case :noFitDataLoaded:
        Error.showErrorResource(Rez.Strings.errorNoFitDataLoaded);
        break;
    }
  }

}
