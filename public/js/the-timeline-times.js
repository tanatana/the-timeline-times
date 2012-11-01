$(function(){
    var $container = $('#container');
    var opts = {
        isAnimated: true,
        isFitWidth: true,
        duration: 400,
        columnWidth : 280,
        itemSelector : '.item'
    };

    $container.imagesLoaded(function(){
        $container.masonry(opts);
    });

    $.autopager({
        content: '.item',
        link: '#next',
        load: function(){
            $container.masonry('appended', $('.item').not('.masonry-brick'));
        }
    });
});
