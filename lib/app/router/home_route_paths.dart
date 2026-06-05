class HomeRoutePaths {
  static const homes = '/homes';
  static const createHome = '/homes/create';
  static const invitations = '/invitations';

  static String members(String homeId) => '/homes/$homeId/members';
  static String invitationsForHome(String homeId) => '/homes/$homeId/invitations';
  static String sendInvitation(String homeId) => '/homes/$homeId/invitations/send';
  static String roles(String homeId) => '/homes/$homeId/roles';
}
