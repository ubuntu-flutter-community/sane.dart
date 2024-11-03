abstract class SaneException implements Exception {}

class SaneUnsupportedException extends SaneException {}

class SaneCancelledException extends SaneException {}

class SaneDeviceBusyException extends SaneException {}

class SaneInvalidException extends SaneException {}

class SaneJammedException extends SaneException {}

class SaneNoDocumentsException extends SaneException {}

class SaneCoverOpenException extends SaneException {}

class SaneIOErrorException extends SaneException {}

class SaneNoMemoryException extends SaneException {}

class SaneAccessDeniedException extends SaneException {}

class SaneNotFoundOption extends SaneException {}
