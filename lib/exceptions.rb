module Exceptions
  
  class AttemptToFakeUser < StandardError
  end

  class AttemptToFakeMembership < StandardError
  end

  class AttemptToFakePrivilege < StandardError
  end

end