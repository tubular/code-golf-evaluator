role Tubular::CodeGolf::Entity::Listable {
    method path returns Supply {}
    method dir-test returns Code { &{ not .starts-with('.') } }
}
