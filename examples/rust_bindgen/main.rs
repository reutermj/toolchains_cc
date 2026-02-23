fn simple_function() -> i64 {
    unsafe { simple_bindgen::simple_function() }
}

fn simple_static_function() -> i64 {
    unsafe { simple_bindgen::simple_static_function() }
}

fn main() {
    println!(
        "The values are {}, {}, and {}!",
        unsafe { simple_bindgen::SIMPLE_VALUE },
        simple_function(),
        simple_static_function(),
    );
}

#[cfg(test)]
mod test {
    #[test]
    fn do_the_test() {
        assert_eq!(42, unsafe { simple_bindgen::SIMPLE_VALUE });
        assert_eq!(1337, super::simple_function());
        assert_eq!(84, super::simple_static_function());
    }
}
