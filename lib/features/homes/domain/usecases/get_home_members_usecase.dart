import '../../data/repositories/home_repository.dart';
import '../../data/models/home_member_model.dart';

class GetHomeMembersUseCase {
  final HomeRepository _repository;

  GetHomeMembersUseCase(this._repository);

  Future<List<HomeMemberModel>> call(String homeId) async {
    return await _repository.getHomeMembers(homeId);
  }
}
