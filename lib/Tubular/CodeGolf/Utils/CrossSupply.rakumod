unit module CrossSupply;

#| Recursively builds cross product of supplies
sub cross-product-recursive($prev, @rest) is export {
    return $prev unless @rest;

    my $head = @rest.first;
    my $result = supply {
        whenever $prev -> @list-element {
            whenever $head -> $element {
                (|@list-element, $element).emit;
            }
        }
    };
    return cross-product-recursive($result, @rest[1..*]);
}

#| Creates cross product of multiple supplies
sub cross-product(**@supplies --> Supply) is export {
    return Supply.from-list(()) unless @supplies;
    return @supplies[0] if @supplies == 1;

    my $initial = supply {
        whenever @supplies.first -> $el {
            ($el,).emit;
        }
    };
    return cross-product-recursive($initial, @supplies[1..*]);
}

#| Multiple supply cross product via X operator
multi sub infix:<X>(Supply $first, *@rest where { .all ~~ Supply } --> Supply) is export {
    cross-product($first, |@rest);
}

