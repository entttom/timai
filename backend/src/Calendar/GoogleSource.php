<?php

/*
 * This file is part of the Kimai time-tracking app.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace App\Calendar;

final class GoogleSource extends CalendarSource
{
    public function __construct(string $id, string $uri, ?string $color = null)
    {
        parent::__construct(CalendarSourceType::GOOGLE, $id, $uri, $color);
    }
}
