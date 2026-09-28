///|
pub extend RonPosition with Eq::{equal, not_equal}

///|
pub extend RonPosition with @debug.Debug::{to_repr}

///|
pub extend RonError with Eq::{equal, not_equal}

///|
pub extend RonError with @debug.Debug::{to_repr}

///|
pub extend RonNumber with Eq::{equal, not_equal}

///|
pub extend RonNumber with @debug.Debug::{to_repr}

///|
pub extend RonRange with Eq::{equal, not_equal}

///|
pub extend RonRange with @debug.Debug::{to_repr}

///|
pub extend RonRange with ToRon::{to_ron}

///|
pub extend RonRange with FromRon::{from_ron}

///|
pub extend RonValue with Eq::{equal, not_equal}

///|
pub extend RonValue with @debug.Debug::{to_repr}

///|
pub extend RonValue with ToRon::{to_ron}

///|
pub extend RonValue with FromRon::{from_ron}

///|
pub extend RonPath with Eq::{equal, not_equal}

///|
pub extend RonPath with @debug.Debug::{to_repr}

///|
pub extend RonDecodeError with Eq::{equal, not_equal}

///|
pub extend RonDecodeError with @debug.Debug::{to_repr}

///|
pub extend RonExtensions with Eq::{equal, not_equal}

///|
pub extend RonExtensions with @debug.Debug::{to_repr}

///|
pub extend RonOptions with Eq::{equal, not_equal}

///|
pub extend RonOptions with @debug.Debug::{to_repr}

///|
pub extend RonDocument with Eq::{equal, not_equal}

///|
pub extend RonDocument with @debug.Debug::{to_repr}
